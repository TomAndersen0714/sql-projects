desc extended category_info;

set hive.execution.engine=mr;
set hive.execution.engine=spark;


explain extended
with t1 as (
  select 1 as a
  union all
  select 2 as a
  union all
  select null as a
)
, t2 as (
  select 1 as a
  union all
  select null as b
)

select *
from t1
left join t2
on t1.a = t2.a;

set hive.exec.max.dynamic.partitions.pernode;
set hive.exec.max.dynamic.partitions;
set hive.server2.thrift.port;
set hive.server2.thrift.bind.host;
dfs -ls /;


list files;

list ARCHIVE[S];

list ARCHIVES;

set -v;

!ls;

set hive.support.quoted.identifiers;
select `(user_id)?+.+` from user_action_table;

select 1;
set hive.metastore.uris;