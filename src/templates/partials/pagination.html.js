<div class="pagination pagination-right">
  <ul>
    <li class="prev<% if (page == 1) print(' disabled'); %>">
        <a<% if (page != 1) { %> href="<%= url(prev) %>"<% } %>>&larr;</a>
    </li>

    <% if (start > 1) { %>
        <li class="first"><a href="<%= url(1) %>">1</a></li>
        <li class="disabled"><a>&hellip;</a></li>
    <% } %>

    <% for (var i = start; i <= end; i++) { %>
        <li<% if (page == i) print(' class="active"'); %>><a href="<%= url(i) %>"><%= i %></a></li>
    <% } %>

    <% if (end < pages) { %>
        <li class="disabled"><a>&hellip;</a></li>
        <li class="last"><a href="<%= url(pages) %>"><%= pages %></a></li>
    <% } %>

    <li class="next<% if (page == pages) print(' disabled'); %>">
        <a<% if (page != pages) { %> href="<%= url(next) %>"<% } %>>&rarr;</a>
    </li>
  </ul>
</div>