(ns vnews-clj.sql
  (:use [clojure.contrib.sql]))

(def db {:classname "org.sqlite.JDBC" ; must be in classpath
        :subprotocol "sqlite"
        :subname "vnews.db"
        ; Any additional keys are passed to the driver
        ; as driver-specific properties.
        :user "root"
        :password ""})

(defn get-where 
  "Loads the query result eagerly"
  [query-str]
  (with-connection db 
    (with-query-results rs query-str (doall rs))))


