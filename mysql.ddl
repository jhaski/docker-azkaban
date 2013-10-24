CREATE DATABASE azkaban2;
GRANT ALL ON azkaban2.* to 'azkaban'@'%' IDENTIFIED BY 'azkaban';
GRANT ALL ON azkaban2.* to 'azkaban'@'localhost' IDENTIFIED BY 'azkaban';