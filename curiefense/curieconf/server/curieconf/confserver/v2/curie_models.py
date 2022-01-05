from flask_restx import fields

# aclprofile

tags_array = fields.List(fields.String(), unique=True, required=True)
aclprofile = {
        "id": fields.String(
            required=True, min_length=1, title="Id", description="Unique id"
        ),
        "name": fields.String(
            required=True,
            min_length=1,
            title="Name",
            description="Name of entity shown in UI"
        ),
        "allow": tags_array,
        "allow_bot": tags_array,
        "deny_bot": tags_array,
        "passthrough": tags_array,
        "deny": tags_array,
        "force_deny": tags_array,
    }

