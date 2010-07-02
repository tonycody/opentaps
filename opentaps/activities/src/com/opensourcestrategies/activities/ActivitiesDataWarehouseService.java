/*
 * Copyright (c) 2010 - 2011 Open Source Strategies, Inc.
 *
 * Opentaps is free software: you can redistribute it and/or modify it
 * under the terms of the GNU Affero General Public License as published
 * by the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * Opentaps is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with Opentaps.  If not, see <http://www.gnu.org/licenses/>.
 */
package com.opensourcestrategies.activities;

import java.sql.Timestamp;
import java.text.DateFormat;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

import org.ofbiz.base.util.Debug;
import org.ofbiz.base.util.UtilMisc;
import org.ofbiz.entity.GenericEntityException;
import org.ofbiz.entity.condition.EntityCondition;
import org.ofbiz.entity.condition.EntityOperator;
import org.opentaps.base.constants.RoleTypeConstants;
import org.opentaps.base.constants.StatusItemConstants;
import org.opentaps.base.constants.WorkEffortPurposeTypeConstants;
import org.opentaps.base.entities.ActivityFact;
import org.opentaps.base.entities.DateDim;
import org.opentaps.base.entities.WorkEffort;
import org.opentaps.base.entities.WorkEffortPartyAssignment;
import org.opentaps.common.reporting.etl.UtilEtl;
import org.opentaps.domain.DomainService;
import org.opentaps.domain.party.Party;
import org.opentaps.domain.party.PartyRepositoryInterface;
import org.opentaps.foundation.entity.EntityNotFoundException;
import org.opentaps.foundation.infrastructure.InfrastructureException;
import org.opentaps.foundation.repository.RepositoryException;
import org.opentaps.foundation.service.ServiceException;

/**
 * Do data warehouse operations for activities.
 */
public class ActivitiesDataWarehouseService extends DomainService {

    private static final String MODULE = ActivitiesDataWarehouseService.class.getName();

    public static List<String> CLIENT_PARTY_ROLES = UtilMisc.toList(RoleTypeConstants.ACCOUNT,
                                                                    RoleTypeConstants.CONTACT,
                                                                    RoleTypeConstants.PROSPECT,
                                                                    RoleTypeConstants.PARTNER);
    private String workEffortId;

    /**
     * Sets the required input parameter for service {@link #transformToAcitivityFacts}.
     * @param workEffortId the ID of work effort
     */
    public void setWorkEffortId(String workEffortId) {
        this.workEffortId = workEffortId;
    }

    /**
     * Transformation which transforms data from WorkEffort, WorkEffortPartyAssign entities to ActivitiesFact entity.
     * It expands the WorkEffortPartyAssign to covers all target parties for all team members.
     * The counts that is in ActivitiesFacts is based on the purpose of the WorkEffort.
     * @throws ServiceException if an error occurs
     */
    public void transformToAcitivityFacts() throws ServiceException {
        try {

            PartyRepositoryInterface repository = getDomainsDirectory().getPartyDomain().getPartyRepository();

            //Get WorkEffortPartyAssign and WorkEffort data by workEffortId.

            WorkEffort workEffort = repository.findOne(WorkEffort.class, repository.map(WorkEffort.Fields.workEffortId, workEffortId));
            List<WorkEffortPartyAssignment> assgmnts = repository.findList(WorkEffortPartyAssignment.class,
                                repository.map(WorkEffortPartyAssignment.Fields.workEffortId, workEffortId));

            // Pass only completed workEfforts to do transformation.
            if (!Arrays.asList(StatusItemConstants.TaskStatus.TASK_COMPLETED, StatusItemConstants.EventStatus.EVENT_COMPLETED).contains(workEffort.getCurrentStatusId())) {
                return;
            }

            // Fill 2 lists according to assigment of work effort to team members (internal parties) and clients (external parties).

            List<WorkEffortPartyAssignment> internalPartiesAssignment = new ArrayList<WorkEffortPartyAssignment>();
            List<WorkEffortPartyAssignment> externalPartiesAssignment = new ArrayList<WorkEffortPartyAssignment>();
            for (int i = 0; i < assgmnts.size(); i++) {
                WorkEffortPartyAssignment assignment = assgmnts.get(i);
                boolean isExternal = false;

                Party assignedParty = repository.getPartyById(assignment.getPartyId());
                if (assignedParty.isAccount()) {
                    isExternal = true;
                } else if (assignedParty.isContact()) {
                    isExternal = true;
                } else if (assignedParty.isLead()) {
                    isExternal = true;
                } else if (assignedParty.isPartner()) {
                    isExternal = true;
                }

                if (isExternal) {
                    externalPartiesAssignment.add(assignment);
                } else {
                    internalPartiesAssignment.add(assignment);
                }
            }

            //Get date dimension ID according to the work effort start date.

            UtilEtl.setupDateDimension(repository.getInfrastructure().getDelegator(), timeZone, locale);
            Timestamp workEffortDate = null;
            if (workEffort.getActualCompletionDate() != null) {
                workEffortDate = workEffort.getActualCompletionDate();
            } else {
                workEffortDate = workEffort.getEstimatedCompletionDate();
            }

            DateFormat dayOfMonthFmt = new SimpleDateFormat("dd");
            DateFormat monthOfYearFmt = new SimpleDateFormat("MM");
            DateFormat yearNumberFmt = new SimpleDateFormat("yyyy");
            String dayOfMonth = dayOfMonthFmt.format(workEffortDate);
            String monthOfYear = monthOfYearFmt.format(workEffortDate);
            String yearNumber = yearNumberFmt.format(workEffortDate);

            EntityCondition dateDimConditions = EntityCondition.makeCondition(EntityOperator.AND,
            EntityCondition.makeCondition(DateDim.Fields.dayOfMonth.name(), dayOfMonth),
            EntityCondition.makeCondition(DateDim.Fields.monthOfYear.name(), monthOfYear),
            EntityCondition.makeCondition(DateDim.Fields.yearNumber.name(), yearNumber));

            Long dateDimId = UtilEtl.lookupDimension(DateDim.class.getSimpleName(), DateDim.Fields.dateDimId.getName(), dateDimConditions, repository.getInfrastructure().getDelegator());

            // Associate all team member with clients (add this association if it is not in the place)
            // and increase count according to WorkEffor workEffortPurposeTypeId.

            for (int i = 0; i < externalPartiesAssignment.size(); i++) {
                WorkEffortPartyAssignment external = externalPartiesAssignment.get(i);

                // Find out what type is external party: is it lead, is it account, ...

                String targetPartyRoleTypeId = null;
                Party assignedParty = repository.getPartyById(external.getPartyId());
                if (assignedParty.isAccount()) {
                    targetPartyRoleTypeId = RoleTypeConstants.ACCOUNT;
                } else if (assignedParty.isContact()) {
                    targetPartyRoleTypeId = RoleTypeConstants.CONTACT;
                } else if (assignedParty.isLead()) {
                    targetPartyRoleTypeId = RoleTypeConstants.LEAD;
                } else if (assignedParty.isPartner()) {
                    targetPartyRoleTypeId = RoleTypeConstants.PARTNER;
                }

                for (int j = 0; j < internalPartiesAssignment.size(); j++) {
                    WorkEffortPartyAssignment internal = internalPartiesAssignment.get(j);

                    // Try to find ActivityFact with such target party id and member party id and date dimension combination.
                    // If not such, then create it.

                    EntityCondition partiesCond = EntityCondition.makeCondition(EntityOperator.AND,
                    EntityCondition.makeCondition(ActivityFact.Fields.targetPartyId.name(), EntityOperator.EQUALS, external.getPartyId()),
                    EntityCondition.makeCondition(ActivityFact.Fields.teamMemberPartyId.name(), EntityOperator.EQUALS, internal.getPartyId()),
                    EntityCondition.makeCondition(ActivityFact.Fields.targetPartyRoleTypeId.name(), EntityOperator.EQUALS, targetPartyRoleTypeId),
                    EntityCondition.makeCondition(ActivityFact.Fields.teamMemberPartyRoleTypeId.name(), EntityOperator.EQUALS, internal.getRoleTypeId()),
                    EntityCondition.makeCondition(ActivityFact.Fields.dateDimId.name(), EntityOperator.EQUALS, dateDimId));
                    List<ActivityFact> activityFacts = repository.findList(ActivityFact.class, partiesCond);

                    ActivityFact activityFact = null;
                    if (activityFacts.size() > 0) {
                        activityFact = activityFacts.get(0);
                    } else {
                        activityFact = new ActivityFact();
                        activityFact.setActivityFactId(repository.getInfrastructure().getSession().getNextSeqId(ActivityFact.class.getSimpleName()));
                        activityFact.setTargetPartyId(external.getPartyId());
                        activityFact.setTeamMemberPartyId(internal.getPartyId());
                        activityFact.setDateDimId(dateDimId);
                        activityFact.setEmailActivityCount(Long.valueOf(0));
                        activityFact.setPhoneCallActivityCount(Long.valueOf(0));
                        activityFact.setVisitActivityCount(Long.valueOf(0));
                        activityFact.setOtherActivityCount(Long.valueOf(0));
                        activityFact.setTargetPartyRoleTypeId(targetPartyRoleTypeId);
                        activityFact.setTeamMemberPartyRoleTypeId(internal.getRoleTypeId());
                    }

                    // Increase count according to WorkEffor workEffortPurposeTypeId.

                    String purpose = workEffort.getWorkEffortPurposeTypeId();
                    if (purpose == null) {
                        activityFact.setOtherActivityCount(activityFact.getOtherActivityCount() + 1);
                    } else if (purpose.compareTo(WorkEffortPurposeTypeConstants.WEPT_TASK_EMAIL) == 0) {
                        activityFact.setEmailActivityCount(activityFact.getEmailActivityCount() + 1);
                    } else if (purpose.compareTo(WorkEffortPurposeTypeConstants.WEPT_TASK_PHONE_CALL) == 0) {
                        activityFact.setPhoneCallActivityCount(activityFact.getPhoneCallActivityCount() + 1);
                    } else if (purpose.compareTo(WorkEffortPurposeTypeConstants.WEPT_MEETING) == 0) {
                        activityFact.setVisitActivityCount(activityFact.getVisitActivityCount() + 1);
                    } else {
                        activityFact.setOtherActivityCount(activityFact.getOtherActivityCount() + 1);
                    }

                    repository.createOrUpdate(activityFact);

                    Debug.logInfo("ActivityFact entity record [" + activityFact.getActivityFactId() + "] created/updated.", MODULE);
                }
            }

        } catch (RepositoryException ex) {
            Debug.logError(ex, MODULE);
            throw new ServiceException(ex);
        } catch (GenericEntityException ex) {
            Debug.logError(ex, MODULE);
            throw new ServiceException(ex);
        } catch (InfrastructureException ex) {
            Debug.logError(ex, MODULE);
            throw new ServiceException(ex);
        } catch (EntityNotFoundException ex) {
            Debug.logError(ex, MODULE);
            throw new ServiceException(ex);
        }
    }

}


















