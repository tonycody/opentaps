<#--
 * Copyright (c) 2006 - 2009 Open Source Strategies, Inc.
 * 
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the Honest Public License.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * Honest Public License for more details.
 * 
 * You should have received a copy of the Honest Public License
 * along with this program; if not, write to Funambol,
 * 643 Bair Island Road, Suite 305 - Redwood City, CA 94063, USA
-->

<@import location="component://opentaps-common/webapp/common/includes/lib/opentapsFormMacros.ftl"/>

<form method="get" name="ApprovedInternalRequirements" action="<@ofbizUrl>ApprovedInternalRequirements</@ofbizUrl>">
  <div class="subSectionBlock">
    <table class="listTable">
      <@inputAutoCompleteProductRow title=uiLabelMap.ProductProduct name="productId" form="ApprovedInternalRequirements"/>
      <@inputSelectRow name="facilityId" title=uiLabelMap.WarehouseProductionFacility list=facilities key="facilityId" displayField="facilityName" required=false />
      <@inputSubmitRow title=uiLabelMap.CommonFind />
    </table>
  </div>
</form>

<form method="post" name="internalRequirementForm" action="<@ofbizUrl>createProductionRunsFromPendingInternalRequirements</@ofbizUrl>">
  <table class="listTable">
    <tr class="listTableHeader">
      <td>${uiLabelMap.ProductProduct}</td>
      <td>${uiLabelMap.CommonQuantity}</td>
      <td>${uiLabelMap.ProductFacility}</td>
      <td>${uiLabelMap.ManufacturingRoutingId}</td>
      <td>${uiLabelMap.CommonStartDateTime}</td>
      <td><@inputMultiSelectAll form="internalRequirementForm"/></td>
    </tr>

    <#list requirementList as requirement>
      <tr class="${tableRowClass(requirement_index)}">
        <@inputHidden name="requirementId" value=requirement.requirementId index=requirement_index />
        <@displayCell text=requirement.productId />
        <@displayCell text=requirement.quantity />
        <@inputSelectCell name="facilityId" list=facilities key="facilityId" displayField="facilityName" index=requirement_index default=requirement.facilityId! ignoreParameters=true />
        <@inputLookupCell name="routingId" index=requirement_index form="internalRequirementForm" lookup="LookupRouting" />
        <@displayDateCell date=requirement.requirementStartDate! />
        <@inputMultiCheckCell index=requirement_index />
      </tr>
    </#list>

    <tr>
      <td colspan="4" align="right">
        <@inputSubmit title=uiLabelMap.WarehouseCreateProductionRun />
        <@inputSubmit onClick="javascript:this.form.action='cancelInternalRequirements'; opentaps.confirmSubmitAction('${uiLabelMap.OpentapsAreYouSure}', this.form);" title="${uiLabelMap.CommonCancel}"/>
      </td>
      <td/>
    </tr>

    <@inputHiddenUseRowSubmit />
    <@inputHiddenRowCount list=requirementList />
  </table>
</form>
