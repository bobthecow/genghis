<td>
    <a href="<%= obj.url() %>" class="name"><%= obj.get('name') %></a>
</td>
<td>
    <span class="collections"><%= obj.get('count') %></span>
</td>
<td>
    <span class="size"><%= Genghis.Util.humanizeSize(obj.get('size')) %></span>
</td>
<td class="action-column">
    <button class="btn small danger destroy">Remove</button>
</td>