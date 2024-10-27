set hive.stats.autogather=false;

drop table test_partition;
create table test_partition
(
  name string
)
partitioned by (ds string);

describe formatted test_partition;

analyze table test_partition compute statistics;

insert into test_partition (name, ds)
values ("tom", "2024-05-23");

set hive.mapjoin.smalltable.filesize
