% The Little SingleStore Book
% Albert Vernon
% November 2020

# Preface {-}

As a consultant at SingleStore (formerly MemSQL), I traveled the world, ate great food, and taught customers how to use our product. I saw which parts were confusing and learned how to explain them to new users. We have reference documentation and training, but customers asked me for a book that explains the concepts behind SingleStore. After you read this slim volume, you will understand how SingleStore works, the names of its components, and how to use the product well. This book is conceptual, so it does not discuss command syntax; for that I refer you to `docs.memsql.com`.

# A Tour of SingleStore

In this chapter, I introduce the SingleStore product, describe how it works, and name the components of the system.

## Why Use SingleStore

Our customers love SingleStore becasue of the three S's, which are speed, scale, and SQL.

* **Speed:** because of its distributed architecture, query compilation, and massive parallelism, SingleStore can give 10X or better performance at $\frac{1}{3}$ the cost compared to other database systems.
* **Scale:** it is easy to add more nodes to increase storage or computational capacity to your SingleStore cluster with a few commands.
* **SQL:** the SingleStore engine uses the query language that your database developers already know. It is also compatible with the MySQL wire protocol, so it is often possible to reuse applications, tools, and drivers.

## Single-Server DBMS

Let us review the single-server architecture that you already know from other database management systems (DBMSes). In this client-server model, you have one or more client programs that connect to a database server, submit Structured Query Language (SQL) statements, and get results back as row sets.

![Non-distributed architecture](non-distributed-architecture)

## Distributed DBMS

SingleStore is a distributed database system. For client programs, the situation is the same as before: they connect to a server called an aggregator, submit SQL statements, and receive results from the aggregator.

Behind the scenes, there are servers in your cluster called leaf nodes. Leaf nodes are the workhorses of your cluster and are responsible for storing and processing the data of your databases. The aggregator is aware of which leaves contain which data. When the aggregator receives a query from a client, the aggregator queries the leaves, combines the results from the leaves into a single result set, and returns the result to the client.

![Distributed architecture](distributed-architecture)

## Database Partitions

An important consideration in a distributed database system is *what* does the system distribute and *how*? In SingleStore, the system divides each database into partitions and stores those partitions on the leaf nodes. A database partition is a container that holds a subset of the rows of the tables of a database. In other words, a partition is a piece of a database. In this example, there are four leaf nodes, and each leaf node stores and processes data for four database partitions.

## Shard Keys
