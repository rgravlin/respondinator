# RESPONDINATOR

## How to build

    $> docker build -f Dockerfile.respondinator .
    $> docker run --rm -p 4568:4568 <CONTAINER_ID>

## Adding routes (POST)

String response route:

    $> curl -s -d '{"path": "/hello", "response": "world"}' localhost:4568/addme 
    $> curl -s localhost:4568/hello 
    world

JSON response route:

    $> curl -s -d '{"path": "/hello", "response": { "world": { "hello": "world" } }}' localhost:4568/addme 
    $> curl -s localhost:4568/hello 
    {"world":{"hello":"world"}}

Respondinator response:

    {
      "path": "/hello",
      "response": "world",
      "key": "b08421d1-4cd5-4668-96d2-bf1467430db5"
    }

## Updating routes (PUT)

    $> curl -s -XPUT -d '{"path": "/hello", "response": { "world": { "hello": "dbag" } }, "key": "b08421d1-4cd5-4668-96d2-bf1467430db5"}' localhost:4568/addme
    $> curl -s localhost:4568/hello
    {"world":{"hello":"dbag"}}

## Retrieving route (GET)

    $> curl -s localhost:4568/addme | jq .
    {
      "world": {
        "hello": "dbag"
      }
    }
