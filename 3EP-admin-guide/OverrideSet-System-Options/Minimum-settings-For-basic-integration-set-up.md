## Minimum settings For basic integration set up

The following settings are the basics required to use 3E Proforma:

<table style="width:100%;">
<colgroup>
<col style="width: 8%" />
<col style="width: 17%" />
<col style="width: 25%" />
<col style="width: 24%" />
<col style="width: 24%" />
</colgroup>
<thead>
<tr>
<th><strong>#</strong></th>
<th><strong>System Options Group</strong></th>
<th><strong>Option</strong></th>
<th><strong>Description</strong></th>
<th><strong>Default Setting</strong></th>
</tr>
</thead>
<tbody>
<tr>
<td><strong>1</strong></td>
<td>3E Proforma</td>
<td>Use Billing Workflow</td>
<td>Use Billing Workflow</td>
<td>False</td>
</tr>
<tr>
<td><strong> </strong></td>
<td> </td>
<td> </td>
<td colspan="2"><strong>Note:</strong> Once set to TRUE, all proformas generated in the system will trigger the workflow and will be accessible only from workflow inbox. This is handled in the Business Object ProformaGeneration.</td>
</tr>
<tr>
<td><strong>2</strong></td>
<td>Framework</td>
<td>EnableObjectAudit</td>
<td>Enables object level auditing</td>
<td>False</td>
</tr>
<tr>
<td><strong> </strong></td>
<td> </td>
<td> </td>
<td colspan="2"><strong>Note:</strong> Once set to True, in the 3E Wf_ProformaEdit process there will be visual indicators of changes made to certain attributes and the list of changes made to allows Billers in 3E to view edits made by users in 3E Proforma (a red triangle on the field indicates a change was made and the original value is viewable).</td>
</tr>
</tbody>
</table>

Review the other AI Group, Billing, 3E Proforma, and 3E Proforma Security system options listed below for additional setup options.

