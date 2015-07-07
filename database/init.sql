set names utf8;

-- create a specific user and database for this app
set @user = "default";
set @pass = "default";
set @mhost = "%";
set @db   = "default";
set @root_pass = "root";

-- create database
set @db_sql = concat('create database `', @db, '` default charset utf8 collate utf8_general_ci');
prepare stmt1 from @db_sql;
execute stmt1;

-- create user and grant
set @grant_sql = concat('grant all on `', @db, '`.* to ',
                     quote(@user), '@', quote(@mhost),
                     ' identified by ', quote(@pass));
prepare stmt2 from @grant_sql;
execute stmt2;

-- drop default test database
drop database if exists test;

-- update root password
update mysql.user set password=password(@root_pass) where user='root';

flush privileges;
