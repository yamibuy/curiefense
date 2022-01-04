from flask_restx import Api, fields
from flask import Blueprint

api_bp = Blueprint("api_v2", __name__)
api = Api(api_bp, version="2.0", title="Curiefense configuration API server v2.0")

# aclprofile

tags_array = fields.List(fields.String(), unique=True, required=True)
m_aclprofile = api.model(
    "ACL Profile",
    {
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
    },
    strict=True
)
