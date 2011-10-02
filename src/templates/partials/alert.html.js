<div class="alert-message<% if (block) { %> block-message<% } %> <%= level %>">
  <a class="close" href="#">×</a>
  <% if (block) { %>
    <p><%= msg %></p>
  <% } else { %>
    <%= msg %>
  <% } %>
</div>