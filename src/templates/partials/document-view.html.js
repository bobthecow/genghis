<div class="well">
    <div class="document-actions">
        <button class="btn btn-small btn-primary save">Save</button>
        <button class="btn btn-small cancel">Cancel</button>
        <button class="btn btn-small edit">Edit</button>
        <button class="btn btn-small btn-danger destroy">Delete</button>
    </div>

    <h3>
        <a class="id" href="<%= obj.url() %>"><%= obj.id %></a>
    </h3>

    <div class="document"><%= obj.prettyPrint() %></div>
</div>
