<div class="well">
    <div class="document-actions">
        <button class="save btn small primary">Save</button>
        <button class="cancel btn small">Cancel</button>
        <button class="edit btn small">Edit</button>
        <button class="destroy btn small danger">Delete</button>
    </div>

    <h3>
        <a class="id" href="<%= obj.url() %>"><%= obj.id %></a>
    </h3>

    <div class="document"><%= obj.prettyPrint() %></div>
</div>
