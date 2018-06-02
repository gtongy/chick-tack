---
date: "2018-06-02"
linktitle: "MySQL: Duplicate entry for primary keyでつまづいた"
title: "MySQL: Duplicate entry for primary keyでつまづいた"
tags: ["MySQL"]
weight: 16
---

## はじめに

MySQLでレコードをINSERTしようとした時に、一意性制約でレコードをINSERT出来ずにつまづいた。

## 表示されたエラーコード

```sh
SQLSTATE[23000]: Integrity constraint violation: 1062 Duplicate entry 'x x xxxx' for key 'unique-key-name'
```

## そもそも一意性制約って？

> The UNIQUE constraint ensures that all values in a column are different.  
> [SQL UNIQUE Constraint](https://www.w3schools.com/sql/sql_unique.asp)

列内の全ての値が異なっていることを保証する制約のこと。
例えば下のクエリで例を示す。
```sql
CREATE TABLE actor (
    id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    title VARCHAR(255) NOT NULL,
    UNIQUE KEY actor_title(name, title)
);
```
各演者がいて、演者名(name)、作品のタイトル(title)に対して一意性制約(UNIQUE KEY)をかける。
この時に(name, title)それぞれがセットで一意であることを保証して、このセット内で同じレコードを入れないように初期のDB設計では設計されていたとします。
```sh
mysql> SHOW INDEX FROM actor WHERE Key_name="actor_title";
+-------+------------+-------------+--------------+-------------+-----------+-------------+----------+--------+------+------------+---------+---------------+---------+
| Table | Non_unique | Key_name    | Seq_in_index | Column_name | Collation | Cardinality | Sub_part | Packed | Null | Index_type | Comment | Index_comment | Visible |
+-------+------------+-------------+--------------+-------------+-----------+-------------+----------+--------+------+------------+---------+---------------+---------+
| actor |          0 | actor_title |            1 | name        | A         |           0 |     NULL |   NULL |      | BTREE      |         |               | YES     |
| actor |          0 | actor_title |            2 | title       | A         |           0 |     NULL |   NULL |      | BTREE      |         |               | YES     |
+-------+------------+-------------+--------------+-------------+-----------+-------------+----------+--------+------+------------+---------+---------------+---------+
2 rows in set (0.00 sec)
```
この時(name, title)の制約が一意性制約です。

## ここに新しいキーを追加してINSERTを実行した

ここで、一人三役の演劇

 - 山田物語
    - 登場人物
        - 山田 香役: 大石唯
        - 山田 優役: 大石唯
        - 山田 さおり役: 大石唯

この増えた役(act)のカラムを追加したいという要件が出てきたとします。

```sh
mysql> ALTER TABLE actor ADD act VARCHAR(255) NOT NULL;
Query OK, 0 rows affected (0.11 sec)
Records: 0  Duplicates: 0  Warnings: 0
mysql> SHOW COLUMNS FROM actor;
+-------+--------------+------+-----+---------+----------------+
| Field | Type         | Null | Key | Default | Extra          |
+-------+--------------+------+-----+---------+----------------+
| id    | int(11)      | NO   | PRI | NULL    | auto_increment |
| name  | varchar(255) | NO   | MUL | NULL    |                |
| title | varchar(255) | NO   |     | NULL    |                |
| act   | varchar(255) | NO   |     | NULL    |                |
+-------+--------------+------+-----+---------+----------------+
4 rows in set (0.00 sec)
```
そして以下のクエリを発行
```sh
INSERT INTO 
    actor (name, title, act) 
VALUES 
    ('yamada yui', 'story of yamada', 'kaori yamada'),
    ('yamada yui', 'story of yamada', 'yuu yamada'),
    ('yamada yui', 'story of yamada', 'saori oda');
```
結果として以下のエラーを表示

```sh
ERROR 1062 (23000): Duplicate entry 'yamada yui-story of yamada' for key 'actor_title'
```

このエラーが最初出てきた一意性制約によるエラーです。

## 解決法

インデックスの貼り直しを行います。
```SQL
ALTER TABLE actor DROP INDEX actor_title;
ALTER TABLE actor ADD UNIQUE actor_title(name, title, act);
```

テーブルのインデックスの確認
```sh
mysql> SHOW INDEX FROM actor WHERE Key_name="actor_title";
+-------+------------+-------------+--------------+-------------+-----------+-------------+----------+--------+------+------------+---------+---------------+---------+
| Table | Non_unique | Key_name    | Seq_in_index | Column_name | Collation | Cardinality | Sub_part | Packed | Null | Index_type | Comment | Index_comment | Visible |
+-------+------------+-------------+--------------+-------------+-----------+-------------+----------+--------+------+------------+---------+---------------+---------+
| actor |          0 | actor_title |            1 | name        | A         |           0 |     NULL |   NULL |      | BTREE      |         |               | YES     |
| actor |          0 | actor_title |            2 | title       | A         |           0 |     NULL |   NULL |      | BTREE      |         |               | YES     |
| actor |          0 | actor_title |            3 | act         | A         |           0 |     NULL |   NULL |      | BTREE      |         |               | YES     |
+-------+------------+-------------+--------------+-------------+-----------+-------------+----------+--------+------+------------+---------+---------------+---------+
3 rows in set (0.01 sec)
```

再度先ほどのINSERT文を実行
```sh
INSERT IGNORE INTO 
    actor (name, title, act) 
VALUES 
    ('yamada yui', 'story of yamada', 'kaori yamada'),
    ('yamada yui', 'story of yamada', 'yuu yamada'),
    ('yamada yui', 'story of yamada', 'saori oda');
```
テーブルの中身を確認。
```sh
mysql> SELECT * FROM actor ORDER BY id;
+----+------------+-----------------+--------------+
| id | name       | title           | act          |
+----+------------+-----------------+--------------+
|  1 | yamada yui | story of yamada | kaori yamada |
|  2 | yamada yui | story of yamada | yuu yamada   |
|  3 | yamada yui | story of yamada | saori oda    |
+----+------------+-----------------+--------------+
3 rows in set (0.00 sec)
```
しっかり結果が挿入されてますね。

## まとめ

改めて振り返って見ても凡ミスの類でしたが、エラーから読み取れる情報から内部の処理の失敗しているところを読み解く力大事だなと。
同じようなエラーで困った人の助けになれば幸いです。