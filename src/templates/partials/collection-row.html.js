<td>
    <a href="<%= obj.url() %>" class="name"><%= obj.get('name') %></a>
</td>
<td>
    <span class="documents"><%= obj.get('count') %></span>
</td>
<td>
    <span class="indexes"><%= obj.get('indexes').length %></span>
</td>
<td class="action-column">
    <button class="btn small danger destroy">Remove</button>
</td>
