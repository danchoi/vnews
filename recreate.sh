mysqladmin -uroot drop vnews
mysqladmin -uroot create vnews
mysql -uroot vnews < lib/create.sql
