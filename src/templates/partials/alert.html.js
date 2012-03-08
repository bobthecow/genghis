<div class="alert<% if (block) { %> alert-block<% } %> alert-<%= level %>">
  <a class="close" href="#">×</a>
  <% if (block) { %>
    <p><%= msg %></p>
  <% } else { %>
    <%= msg %>
  <% } %>
</div>