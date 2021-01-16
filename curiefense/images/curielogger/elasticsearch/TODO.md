#### Setting up elasticsearch

1. index name should be a variable with default value of 'curieaccesslog' (which will be the alias for the rollver index) --> DONE
1. run mapping at start `PUT /curieaccesslog/_mapping` (see more at https://www.elastic.co/guide/en/elasticsearch/reference/current/mapping.html)
1. set up rollover and retention based on the example below


Define the index name and the alias
```
PUT curieaccesslog-000001
{
  "settings": {
    "index.lifecycle.name": "curie_policy",
    "index.lifecycle.rollover_alias": "curieaccesslog"
  },
  "aliases": {
    "curieaccesslog": {
      "is_write_index": true
    }
  }
}
```

Define the rollover based on either age, size or docs and delete what's older than x days (7 in this case)
```
PUT _ilm/policy/curie_policy
{
  "policy": {
    "phases": {
      "hot": {
        "actions": {
          "rollover" : {
            "max_age": "1d",
            "max_size": "100GB",
            "max_docs": 10000000
          }
        }
      },
      "delete": {
        "min_age": "7d",
        "actions": {
          "delete": {}
        }
      }
    }
  }
}

```


```
curl -s -H "Content-Type: application/x-ndjson" -XPUT localhost:9200/flatcurieaccesslog --data-binary @type-mapping.json
```