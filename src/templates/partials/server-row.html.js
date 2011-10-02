<% if (obj.get('error')) { %>
    <td>
        <%= obj.get('name') %>
        <span class="label important" title="<%= Genghis.Util.escape(obj.get('error')) %>">Error</span>
    </td>
    <td></td>
    <td></td>
<% } else { %>
    <td>
        <a href="<%= obj.url() %>" class="name"><%= obj.get('name') %></a>
    </td>
    <td>
        <span class="databases"><%= obj.get('count') %></span>
    </td>
    <td>
        <span class="size"><%= Genghis.Util.humanizeSize(obj.get('size')) %></span>
    </td>
<% } %>
<td class="action-column">
    <button class="btn small danger destroy">Remove</button>
</td>