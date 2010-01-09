package org.opentaps.base.entities;

/*
 * Copyright (c) 2008 - 2009 Open Source Strategies, Inc.
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

// DO NOT EDIT THIS FILE!  THIS IS AUTO GENERATED AND WILL GET WRITTEN OVER PERIODICALLY WHEN THE DATA MODEL CHANGES
// EXTEND THIS CLASS INSTEAD.

import java.sql.Timestamp;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;

import javax.persistence.CascadeType;
import javax.persistence.Column;
import javax.persistence.FetchType;
import javax.persistence.GeneratedValue;
import javax.persistence.Id;
import javax.persistence.JoinColumn;
import javax.persistence.ManyToOne;
import javax.persistence.OneToMany;

import javolution.util.FastMap;

import org.opentaps.foundation.entity.Entity;
import org.opentaps.foundation.entity.EntityFieldInterface;
import org.opentaps.foundation.repository.RepositoryException;
import org.opentaps.foundation.repository.RepositoryInterface;
import javax.persistence.*;
import org.hibernate.search.annotations.*;
<#-- imports for all the fields' types -->
<#list types as type>
import ${type};
</#list>

/**
 * Auto generated base entity ${name}.
 */
@javax.persistence.Entity
<#if isNeedIndex>
@Indexed
</#if>
<#if !isView>
@Table(name="${tableName}")
<#else>
<#-- declare namedNativeQuery for view-entity -->
@NamedNativeQuery(name="select${name}s", query="${query}", resultSetMapping="${name}Mapping")
@SqlResultSetMapping(name="${name}Mapping", entities={
@EntityResult(entityClass=${name}.class, fields = {
<#-- generate field mapping -->
<#assign n = 0 />
<#list fields as field>
<#if fieldMapAlias.containsKey(field)>
<#if n gt 0>,</#if>@FieldResult(name="${field}", column="${field}")
<#assign n = n+1 /> 
</#if>
</#list>
})})
@org.hibernate.annotations.Entity(mutable = false)
@org.hibernate.annotations.AccessType("field")
</#if>
public class ${name} extends Entity {
static {
java.util.Map<String, String> fields = new java.util.HashMap<String, String>();
<#list fields as field>
<#-- put field/column mapping into fieldMapColumns-->
<#if isView && fieldMapColumns.containsKey(field)>
        fields.put("${field}", "${fieldMapColumns.get(field)}");
<#elseif !isView && columnNames.containsKey(field)>
        fields.put("${field}", "${columnNames.get(field)}");
</#if>
</#list>
fieldMapColumns.put("${name}", fields);
}
  public static enum Fields implements EntityFieldInterface<${name}> {
  <#list fields as field>
    ${field}("${field}")<#if field_has_next>,<#else>;</#if>
  </#list>
    protected final String fieldName;
    private Fields(String name) { fieldName = name; }
    /** {@inheritDoc} */
    public String getName() { return fieldName; }
    /** {@inheritDoc} */
    public String asc() { return fieldName + " ASC"; }
    /** {@inheritDoc} */
    public String desc() { return fieldName + " DESC"; }
  }

<#-- define id and getter/setter for multi-pk class -->
<#if !isView && (primaryKeys.size() gt 1)>
   @EmbeddedId
<#if isNeedIndex>   @DocumentId</#if>
   <#-- define field bridge for IdClass -->
   @FieldBridge(impl = org.opentaps.base.entities.bridge.${name}PkBridge.class)
     protected ${name}Pk id = new ${name}Pk();
   
    /**
     * Auto generated Id accessor.
     * @return <code>${name}Pk</code>
     */
      public ${name}Pk getId() {
         return id;
      }
    /**
     * Auto generated Id setter.
     * @param id a <code>${name}Pk</code> value to set
    */   
      public void setId(${name}Pk id) {
         this.id = id;
      }
</#if>
  <#-- declare all the fields -->
  <#list fields as field>
  <#if isView>
    <#if viewEntityPks.contains(field)>@Id</#if>
   private <#if !fieldMapAlias.containsKey(field)>transient </#if>${fieldTypes.get(field)} ${field};
  <#elseif !primaryKeys.contains(field) || primaryKeys.size()==1>
  <#-- do not declare the field if it is a field of composite key -->
    <#if primaryKeys.contains(field) && primaryKeys.size() == 1>
        <#if "SequenceValueItem" != name>
        <#assign fieldShortType = fieldTypes.get(field)/>
        <#if "Long" == fieldShortType || "Integer" == fieldShortType>
   @org.hibernate.annotations.GenericGenerator(name="${name}_GEN",  strategy="increment")
        <#else>
   @org.hibernate.annotations.GenericGenerator(name="${name}_GEN",  strategy="org.opentaps.foundation.entity.hibernate.OpentapsIdentifierGenerator")
        </#if>
   @GeneratedValue(generator="${name}_GEN")
        </#if>
   @Id
<#if isNeedIndex>
   @DocumentId
</#if>        
    </#if>
<#if !isView>
<#if indexWeights.containsKey(field)>   @org.hibernate.search.annotations.Fields( {
     <#if "UN_TOKENIZED" == tokenTypes.get(field)>
       <#-- if the field is set to UN_TOKENIZED also index as TOKENIZED to allow sort and lower case search -->
       @Field(index=Index.TOKENIZED, store=Store.NO),
     </#if>
     @Field(index=Index.${tokenTypes.get(field)}, store=Store.YES)
   } )
   @Boost(${indexWeights.get(field)}f)
</#if>
   @Column(name="${columnNames.get(field)}")
</#if> 
   protected ${fieldTypes.get(field)} ${field};
  </#if>
  </#list>
  <#-- fields related to relations, used to cache -->
  <#list relations as relation>
   <#if relation.joinColumn?has_content && !viewEntities.contains(relation.entityName) && "Y" == relation.isNeedMapping>
    <#if "many" == relation.type>
     <#if primaryKeys.size() == 1>
     <#-- oneToMany -->
   @OneToMany(fetch=FetchType.LAZY<#-- add cascade annotations --><#if relation.itemName?has_content>, mappedBy="${relation.refField}", cascade = {CascadeType.PERSIST, CascadeType.MERGE, CascadeType.REMOVE}</#if>)
   @JoinColumn(name="${relation.joinColumn}")
   <#if isNeedIndex && needIndexEntities.contains(relation.entityName)>@ContainedIn</#if>
     </#if>
    <#else>
      <#-- manyToOne -->
   <#if ("Y" == relation.isOneToOne)>@OneToOne<#else>@ManyToOne</#if>(cascade = {CascadeType.PERSIST, CascadeType.MERGE}, fetch=FetchType.LAZY)
   @JoinColumn(name="${relation.joinColumn}"<#if "Y" == relation.isRepeated>, insertable=false, updatable=false</#if>)
   <#if "Y" == relation.isRepeated>@org.hibernate.annotations.Generated(
      org.hibernate.annotations.GenerationTime.ALWAYS
   )
     </#if>
     <#-- if not view entity and not one-to-one relation, then add IndexedEmbedded annotation -->
   <#if isNeedIndex && needIndexEntities.contains(relation.entityName)>@IndexedEmbedded(depth = 2)</#if>
    </#if>
   protected <#if "many" == relation.type><#if (primaryKeys.size() > 1) || (isView && !fieldMapAlias.containsKey(relation.fieldName))>transient </#if>List<${relation.entityName}><#else>${relation.entityName}</#if> ${relation.fieldName} = null;
    <#else>
    <#-- multi assocation, cannot map manyToOne and oneToMany -->
   private transient <#if "many" == relation.type>List<${relation.entityName}><#else>${relation.entityName}</#if> ${relation.fieldName} = null;
    </#if>
  </#list>

  <#-- constructor with initialization of the base members -->
  /**
   * Default constructor.
   */
  public ${name}() {
      super();
      this.baseEntityName = "${name}";
      this.isView = ${isView?string};
      <#if resourceName?has_content>this.resourceName = "${resourceName}";</#if>
      this.primaryKeyNames = new ArrayList<String>();
      <#list primaryKeys as pk>this.primaryKeyNames.add("${pk}");</#list>
      this.allFieldsNames = new ArrayList<String>();
      <#list fields as field>this.allFieldsNames.add("${field}");</#list>
      this.nonPrimaryKeyNames = new ArrayList<String>();
      this.nonPrimaryKeyNames.addAll(allFieldsNames);
      this.nonPrimaryKeyNames.removeAll(primaryKeyNames);
  }

  /**
   * Constructor with a repository.
   * @param repository a <code>RepositoryInterface</code> value
   */
  public ${name}(RepositoryInterface repository) {
      this();
      initRepository(repository);
  }

  <#-- set methods -->
  <#if isView>
    /**
     * This is a view-entity, so the setter methods will be private to this class and for use in its fromMap constructor only
     */
  </#if>
  <#list fields as field>
    /**
     * Auto generated value setter.
     * @param ${field} the ${field} to set
     */
    public void ${setMethodNames.get(field)}(${fieldTypes.get(field)} ${field}) {
        <#if !isView && (primaryKeys.size() > 1) && primaryKeys.contains(field)>
        <#-- if it is a field of composite key, the call id setter to set value -->
        id.${setMethodNames.get(field)}(${field});
        <#else>
        this.${field} = ${field};
        </#if>
    }
  </#list>

  <#-- get methods -->
  <#list fields as field>
    /**
     * Auto generated value accessor.
     * @return <code>${fieldTypes.get(field)}</code>
     */
    public ${fieldTypes.get(field)} ${getMethodNames.get(field)}() {
        <#if !isView && (primaryKeys.size() > 1) && primaryKeys.contains(field)>
        <#-- if it is a field of composite key, the call id getter to get value -->
        return this.id.${getMethodNames.get(field)}();
        <#else>
        return this.${field};
        </#if>
    }
  </#list>

  <#-- get methods for relations -->
  <#list relations as relation>
    /**
     * Auto generated method that gets the related <code>${relation.entityName}</code> by the relation named <code>${relation.relationName}</code>.
     * @return <#if "many" == relation.type>the list of<#else>the</#if> <code>${relation.entityName}</code>
     * @throws RepositoryException if an error occurs
     */
    public <#if "many" == relation.type>List<? extends ${relation.entityName}><#else>${relation.entityName}</#if> get${relation.accessorName}() throws RepositoryException {
        if (this.${relation.fieldName} == null) {
            this.${relation.fieldName} = getRelated<#if "one" == relation.type>One</#if>(${relation.entityName}.class, "${relation.relationName}");
        }
        return this.${relation.fieldName};
    }
  </#list>

  <#-- set methods for relations -->
  <#list relations as relation>
    /**
     * Auto generated value setter.
     * @param ${relation.fieldName} the ${relation.fieldName} to set
    */
    public void set${relation.accessorName}(<#if "many" == relation.type>List<${relation.entityName}><#else>${relation.entityName}</#if> ${relation.fieldName}) {
        this.${relation.fieldName} = ${relation.fieldName};
    }
  </#list>

<#-- add methods for collection relations -->
  <#list relations as relation>
  <#if relation.itemName?has_content>
<#-- add item method for collection property -->
    /**
     * Auto generated method that add item to collection.
     */
    public void ${relation.addMethodName}(${relation.entityName} ${relation.itemName}) {
        if (this.${relation.fieldName} == null) {
            this.${relation.fieldName} = new ArrayList<${relation.entityName}>();
        }
        this.${relation.fieldName}.add(${relation.itemName});
    }
<#-- remove item method for collection property -->
    /**
     * Auto generated method that remove item from collection.
     */
    public void ${relation.removeMethodName}(${relation.entityName} ${relation.itemName}) {
        if (this.${relation.fieldName} == null) {
            return;
        }
        this.${relation.fieldName}.remove(${relation.itemName});
    }
<#-- clear all items method for collection property -->
    /**
     * Auto generated method that clear items from collection.
     */
    public void ${relation.clearMethodName}() {
        if (this.${relation.fieldName} == null) {
            return;
        }
        this.${relation.fieldName}.clear();
    }
   </#if>
  </#list>

  <#-- Map conversion methods -->
    /** {@inheritDoc} */
    @Override
    public void fromMap(Map<String, Object> mapValue) {
        preInit();
        <#list fields as field>
        <#-- special handling necessary for BigDecimal, as they are defined as Double by the entity engine fieldtype XML
        and must be converted to BigDecimal using this special method -->
           <#if fieldTypes.get(field) == "BigDecimal">
        ${setMethodNames.get(field)}(convertToBigDecimal(mapValue.get("${field}")));
           <#else>
        ${setMethodNames.get(field)}((${fieldTypes.get(field)}) mapValue.get("${field}"));
           </#if>
        </#list>
        postInit();
    }

    /** {@inheritDoc} */
    @Override
    public Map<String, Object> toMap() {
        Map<String, Object> mapValue = new FastMap<String, Object>();
        <#list fields as field>
        mapValue.put("${field}", ${getMethodNames.get(field)}());
        </#list>
        return mapValue;
    }

    <#-- Do not define any other get/set methods such as getEntityName -- there might be a field called "entityName" in your entity! -->

}
