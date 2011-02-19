create table feeds (
  title varchar(255),
  feed_url varchar(255),
  link varchar(255),
  primary key (feed_url)
) type=MyISAM;

create table items (
  guid varchar(255),
  feed varchar(255), /* feed link is the foreign key */
  feed_title varchar(255), /*denorm a little*/
  title varchar(255),
  link varchar(255),
  pub_date datetime,
  author varchar(255),
  text text,
  word_count int unsigned,
  primary key (feed,guid)
) type=MyISAM;

alter table items add index feed (feed(5));

create table feeds_folders (
  feed varchar(255), /* the feed link */
  folder varchar(255), /* folder title */
  unique key (feed, folder)
) type=MyISAM;

alter table feeds_folders add index folder (folder(5));

