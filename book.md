% The Little SingleStore Book v7.1
% Albert Vernon
% Version %VERSION%, December 2020

# Preface {-}

As a consultant at SingleStore (formerly MemSQL), I taught customers how to use our product and helped with implementations. I saw which parts were confusing and learned how to explain them to new users. We have reference documentation and training, but customers asked me for a book that explains the concepts behind SingleStore DB.

After reading this slim volume, you will understand how SingleStore DB works, the names of its components, and how to use the product well. This book is conceptual, so it does not discuss command syntax; for that I refer you to our online documentation^[https://docs.singlestore.com].

# A Tour of SingleStore DB

In this chapter, I introduce the SingleStore DB product, describe how it works, and name the components of the system.

## Why Use SingleStore DB

Our customers love SingleStore DB becasue of the three S's, which are speed, scale, and SQL.

* **Speed:** because of its distributed architecture, query compilation, and massive parallelism, SingleStore DB can give better performance at a fraction of the cost of other database systems.
* **Scale:** with a few commands you can add nodes to your SingleStore DB cluster to increase storage or computational capacity.
* **SQL:** SingleStore DB uses the query language that your database developers already know. It is also compatible with the MySQL wire protocol, so it is often possible to reuse applications, tools, and drivers.

## Aggregators and Leaves

In a traditional single-server database management system, you have one or more client programs that connect to a database server, submit Structured Query Language (SQL) statements, and get results back as row sets.

![Single-server architecture](single-server-architecture)

In contrast, SingleStore DB is a distributed database system. For client programs, the situation is the same as before: they connect to a server called an *aggregator*, submit SQL statements, and receive results from the aggregator.

![Distributed architecture](distributed-architecture)

Behind the scenes, there are servers in your cluster called *leaf nodes*. Leaf nodes are the workhorses of your cluster and are responsible for storing and processing the data of your databases. The aggregator is aware of which leaves contain which data. When the aggregator receives a query from a client, the aggregator queries the leaves, combines the results from the leaves into a single result set, and returns the result to the client.

**Caution:** Clients should not connect to leaf nodes; they only need to connect to aggregators.

## Database Partitions

An important consideration in a distributed database system is what does the system distribute and how? SingleStore DB divides each database into *partitions* and assigns those partitions to your leaf nodes.

A database partition is a container that holds a subset of the rows of the tables of a database. In other words, a partition is a piece of a database. In this example, there are two leaf nodes. Each leaf node stores and processes data for three database partitions.

![Database partitions](partitions)

When you create a database, you can specify how many partitions it has like this:

```sql
create database mycompany partitions = 6
```

If you omit the `partitions` clause, then SingleStore DB creates your database with the default number of partitions. The number of database partitions has performance implications, especially for concurrency. I discuss this in the Query Tuning chapter.

After you create a database, you cannot alter the number of partitions. If you change your mind, you have these options:

* Use the `backup database with split partitions`^[https://docs.singlestore.com/v7.1/guides/cluster-management/resize-your-cluster/cluster-expansion-steps/cluster-expansion-steps/] command to double the number of partitions in your database backup.
* Export your data, drop the database, re-create the database with the desired number of partitions, re-create your tables, and load data back into the tables.

## Shard Keys

When you create a table in SingleStore DB, you can specify one or more columns to be the *shard key* of the table. The value of the shard key determines which partition holds a given row. In other words, the shard key is the mapping between a row and a database partition.

As you insert data into a table, the aggregator calculates where to store each row using its shard key value. This calculation is repeatable, which means two rows with the same shard key value always go to the same partition, even if the rows belong to different tables. This has performance implications when joining tables, which I discuss in the Query Tuning chapter.

If you specify a multi-column shard key, the aggregator concatenates the values of the shard key columns and then does the calculation. Consider this example:

```sql
create table employees (
  first_name text,
  last_name text,
  shard key (last_name, first_name));

insert into employees values ('John', 'Smith');
```

Because `employees` has a compound shard key, the shard key value for the row is `'SmithJohn'`. Notice that the order of the columns in the `shard key` clause is significant.

When you create a table, the following scenarios are possible:

* If you designate a shard key, then the aggregator uses your designation as the shard key.
* If your table has a primary key but no shard key, then the aggregator uses the primary key as the shard key.
* If your table has neither a shard key nor a primary key, then the aggregator does keyless sharding, which means distributing the rows randomly across your database partitions. This has performance implications that I discuss in the Query Tuning chapter.

After you create a table, you cannot alter the shard key. If you change your mind, you have these options:

* Back up the table, drop the table, then re-create it with a different shard key.
* Create a new table with a different shard key then copy the data with a statement like this: `insert into _____ select * from _____`

Consider this example that makes tables named `foo` and `bar` and inserts sample data:

```sql
create database testdb partitions = 6;
use testdb;

create table foo (
  a int,
  b int,
  c int,
  shard key (b));

create table bar (
  x int,
  y int,
  z int,
  shard key (x));

insert into foo values (4, 5, 6);
insert into bar values (5, 7, 8);
```

The shard key value of the row in `foo` is `5`, so partition #2 stores this row^[If you try this example in your cluster, you might get a different `partition_id()`.]:

```console
memsql [testdb]> select *, partition_id() from foo;
+------+------+------+----------------+
| a    | b    | c    | partition_id() |
+------+------+------+----------------+
|    4 |    5 |    6 |              2 |
+------+------+------+----------------+
```

Here is an illustration of what happened:

![](shard-example-1)

The shard key value of the row in `bar` is also `5`, so partition #2 stores this row in addition to the row in `foo`:

```console
memsql [testdb]> select *, partition_id() from bar;
+------+------+------+----------------+
| x    | y    | z    | partition_id() |
+------+------+------+----------------+
|    5 |    7 |    8 |              2 |
+------+------+------+----------------+
```

![](shard-example-2)

Notice that the same partition stores both rows even though the rows are in different tables and the shard key columns have different names. The shard key value of a row is the only determinant of which partition stores the row.

Lastly, if we insert into `foo` with a different shard key value, partition #4 stores this row:

```console
memsql [testdb]> insert into foo values (1, 10, 9);
memsql [testdb]> select *, partition_id() from foo;
+------+------+------+----------------+
| a    | b    | c    | partition_id() |
+------+------+------+----------------+
|    4 |    5 |    6 |              2 |
|    1 |   10 |    9 |              4 |
+------+------+------+----------------+
```

![](shard-example-3)

Rows with different shard key values are usually in different partitions. This has performance implications when joining tables, which I discuss in the Query Tuning chapter.

### Data Skew

One consideration when choosing a shard key is to spread the rows of your table evenly among your partitions. In other words, you want to pick a shard key that gives a uniform data distrbution. If you pick a bad shard key, it could cause data skew, which is when a partition holds an unbalanced amount of data. If the imbalance is large, then the leaf responsible for the partition has to do extra work, which might slow down your queries. In addition, data skew can exhaust the storage of a leaf with an unbalanced partition. The section "Detecting and Resolving Data Skew"^[https://docs.singlestore.com/v7.1/guides/use-memsql/physical-schema-design/detecting-and-resolving-data-skew/detecting-and-resolving-data-skew] in the SingleStore DB documentation describes how to detect data skew.

Columns with few or no repeating values are good shard keys because they result in uniform data distribution, for example, serial numbers and ID numbers. Columns with repeating values, such as names, are poor shard keys since they are prone to data skew.

Data skew below 10% is usually acceptable, but you should investigate if you detect skew above that threshold.

In this example, partition #1 has twice as much data as the other partitions. This system operator would want to investigate why and possibly change the shard key of responsible table.

![Data skew](data-skew)

The other consideration when selecting a shard key is performance, especially for concurrency and when joining tables, which I discuss in the Query Tuning chapter.
