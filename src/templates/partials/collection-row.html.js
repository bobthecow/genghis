<td>
    <a href="<%= obj.url() %>" class="name value"><%= obj.get('name') %></a>
</td>
<td>
    <span class="documents value"><%= obj.get('count') %></span>
</td>
<td>
    <span class="indexes has-details value"><%= obj.get('indexes').length %></span>
    <div class="details" title="<%= obj.get('indexes').length %> Index<% if (obj.get('indexes').length != 1) { %>es<% } %>">
        <% if (obj.get('indexes').length > 0) { %>
            <ul class="index-details">
                <% _.each(obj.get('indexes'), function(index) { %>
                    <li><%= Genghis.Util.formatJSON(index.key) %></li>
                <% }); %>
            </ul>
        <% } else { %>
            <em>None.</em>
        <% } %>
    </div>
</td>
<td class="action-column">
    <button class="btn small danger destroy">Remove</button>
</td>
