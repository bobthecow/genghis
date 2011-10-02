<% _.each(collection.toArray().slice(0, 10), function(m) { %>
    <li<% if (m.id == model.id) { %> class="active"<% } %>><a href="<%= m.url() %>">
        <%= m.id %>
        <span><%= Genghis.Util.humanizeCount(m.get('count') || 0) %></span>
    </a></li>
<% }); %>
<% if (collection.size() > 10) { %>
    <li class="divider"></li>
    <li><a href="<%= collection.url %>">More &raquo;</a></li>
<% } %>