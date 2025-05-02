# About

- A distributed NoSQL key-value database
- Objects are stored in `buckets` (they are just logical)
- it is distributed across mutliple instances, as a cluster
  - handle a bigger volume of requests.
  - They all share the data and are synchronized automatically.

# schema and indexes

## Notions

- `Lucene`: it is the search engine used by `Solr`, we use it's query language in our HTTP requests.
- `Solr`: it is the indexer used by Riak, responsible for indexing the fields of your objects and finding them when you submit a valid query.
- `Riak`: is our database manager, it takes care of writing and fetching data, and replicates changes in your data across multiple nodes (making a cluster).

In one sentence: `Riak` stores your data, uses `Solr` to organize it, and uses `Lucene`'s language to search it.

## Concept

In Riak, when you want to search through your stored documents (like blog posts, products, customers, etc.), you need two things:

- `Schema`: Describes the structure of your searchable data — what fields exist, their types, how to index them.
- `Index`: A collection of documents that uses a specific schema. It's where your searchable data is stored.

## How it works

1. You save your data into Riak,

   - If you want to search later (by title, author, date...), you have to tell Riak Search how to index it.

2. Define a Schema to tell `Solr` what fields to expect and what/how to index them.

3. Create an Index that is linked to a schema,

   - The index uses the schema to know how to index the data you insert into Riak.

4. Link Buckets to Indexes
   - In Riak, each bucket (where you store objects) can be associated with an index.
   - You tell Riak: "Anything stored in this bucket should be indexed using this index."

✅ Now when you store data, Riak will automatically parse your objects according to the schema, and index them inside the correct index for searching later!

## indexing data

We create indexes by providing a schema: the name and types of the fields to be indexed.

```xml
<schema name="default" version="1.5">
  <fields>
    <field name="id" type="string" indexed="true" stored="true" multiValued="true" />
    <field name="custom.customer.email" type="string" indexed="true" stored="true" multiValued="true" />

    <field name="_yz_id" type="_yz_str" indexed="true" stored="true" multiValued="false"
      required="true" />
    <!-- Riak Key: The key of the Riak object this doc corresponds to. -->
    <field name="_yz_rk" type="_yz_str" indexed="true" stored="true" multiValued="false" />
  </fields>

  <uniqueKey>_yz_id</uniqueKey>

  <types>
    <!-- YZ String: Used for non-analyzed fields -->
    <fieldType name="_yz_str" class="solr.StrField" sortMissingLast="true" />
    <fieldType name="string" class="solr.StrField" sortMissingLast="true" />
    <fieldType name="boolean" class="solr.BoolField" sortMissingLast="true" />
  </types>
</schema>
```

It has three big sections:

- <fields> — What fields your documents will have.

  - The `name` is the field name in your JSON. If it's nested, you should put an point to separate the parent field from the child one, like `custom.customer.email`.
  - `type` is the type of the indexed value. These types are defined later by the tag fieldType
  - `indexed` and `stored` should always be set as true
  - `multiValued` indicates that your field can contain a list of item and Solr should extend its research on all values of your field.
  - `_yz_*` fields are mandatory fields. They don't have to be represented in your JSON fields. They are created by `Solr` when your data is indexed.

- <uniqueKey> — Which field uniquely identifies each document.

  - `uniqueKey` tag is also a mandatory tag for `Solr` to retreive its indexed data

- <types> — What types of data each field can be.
  - `fieldType` tag is a declaration of a new index type usable in the type field of the field tag. They should be declared inside `types` tag
    - `class` is the `Solr` class on which your type is based (look in the documentation).

### _yz_\* fields

Riak uses these internally for search and consistency.

- `_yz_id`: Unique ID for the document (like a primary key).
- `_yz_ed`: Entropy Data: for anti-entropy processes (internal consistency checking).
- `_yz_pn`: Partition number (for filtering by partition when searching).
- `_yz_fpn`: First partition number (for optimizing overlap queries).
- `_yz_vtag`: Version tag (used when there are siblings/versions of an object).
- `_yz_rk`: The Riak key of the object.
- `_yz_rt`: Bucket type the object belongs to.
- `_yz_rb`: Bucket name the object belongs to.
- `_yz_err`: Error flag — set if there was a failure in processing the object.

# To see

Masterless
the ring
how it index
