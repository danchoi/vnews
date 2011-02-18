create table feeds (
  title varchar(255),
  link varchar(255),
  primary key (link)
) type=MyISAM;

create table items (
  guid varchar(255),
  feed varchar(255),
  feed_title varchar(255), /*denorm a little*/
  title varchar(255),
  link varchar(255),
  pub_date datetime,
  author varchar(255),
  text text,
  primary key (guid)
) type=MyISAM;

alter table items add index feed (feed(5));
