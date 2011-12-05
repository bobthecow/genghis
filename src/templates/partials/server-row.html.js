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
        <span class="databases has-details"><%= obj.get('count') %></span>
        <div class="details" title="<%= obj.get('count') %> Database<% if (obj.get('count') != 1) { %>s<% } %>">
            <% if (obj.get('count') > 0) { %>
                <ul>
                    <% _.each(_.first(obj.get('databases'), 15), function(database) { %>
                        <li><%= database %></li>
                    <% }); %>
                    <% if (obj.get('count') > 15) { %>
                        <li>&hellip;</li>
                    <% } %>
                </ul>
            <% } else { %>
                <em>None.</em>
            <% } %>
        </div>
    </td>
    <td>
        <span class="size"><%= Genghis.Util.humanizeSize(obj.get('size')) %></span>
    </td>
<% } %>
<td class="action-column">
    <button class="btn small danger destroy">Remove</button>
</td>