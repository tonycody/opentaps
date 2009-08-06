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

<#-- Note this file is a cousin to receiveOutsourcedPO.ftl -->
<div class="subSectionBlock">
  <div class="form">
  <form method="GET" action="<@ofbizUrl>invoiceSupplies</@ofbizUrl>" name="invoiceOrder">
    <span class="tableheadtext">${uiLabelMap.OrderOrderId}: </span>
    <@inputLookup name="orderId" lookup="LookupPurchaseOrder" form="invoiceOrder"/>
    <@inputSubmit title=uiLabelMap.OpentapsFindOrder />
    <@displayError name="orderId"/>
  </form>
  </div>
</div>

<#if orderItems?exists && orderItems.size() != 0>
<form method="post" action="<@ofbizUrl>createSuppliesInvoice?orderId=${parameters.orderId}</@ofbizUrl>" name="createSuppliesInvoice">

  <table class="listTable">
      <tr class="listTableHeader">
          <td>${uiLabelMap.CommonDescription}</td>
          <td>${uiLabelMap.OrderRemaining}</td>
          <td align="right">${uiLabelMap.OrderUnitPrice}</td>
          <td align="right">${uiLabelMap.OrderRemainingSubTotal}</td>
          <td align="right">${uiLabelMap.OpentapsQtyToInvoice}</td>
          <td></td>
      </tr>

      <#list orderItems as orderItem>
          <@inputHidden name="orderId" value=orderItem.orderId index=orderItem_index />
          <@inputHidden name="orderItemSeqId" value=orderItem.orderItemSeqId index=orderItem_index />
          <@inputHiddenRowSubmit index=orderItem_index />

          <tr class="${tableRowClass(orderItem_index)}">
              <td>${orderItem.itemDescription?default(orderItem.productId?default(orderItem.comments?default(orderItem.orderItemSeqId)))}</td>
              <td>${orderItem.quantity}</td>
              <@displayCurrencyCell amount=orderItem.unitPrice currencyUomId=order.currencyUom />
              <@displayCurrencyCell amount=(orderItem.unitPrice * orderItem.quantity) currencyUomId=order.currencyUom />
              <td align="right">
                  <@inputText name="quantity" index=orderItem_index size=6 />
              </td>
              <td><@displayError name="quantity" index=orderItem_index /></td>
          </tr>
      </#list >

      <tr>
          <td colspan="4"></td>
          <@inputSubmitCell title=uiLabelMap.PurchInvoiceSupplies blockClass="textright" />
          <td></td>
      </tr>
  </table>

</form>
<#elseif orderItems?exists && orderItems.size() == 0>
  <div class="form"><span class="tableheadtext">${uiLabelMap.OpentapsNothingToInvoice}</span></div>
</#if>
