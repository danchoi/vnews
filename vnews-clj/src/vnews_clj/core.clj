(ns vnews-clj.core
  (:use [feedparser-clj.core :only [parse-feed]])
  (:require [clojure.contrib.string :as string]))

; test fetching feeds
(def f (parse-feed "http://www.nytimes.com/services/xml/rss/nyt/HomePage.xml"))

; (def g (parse-feed "http://www.nytimes.com/services/xml/rss/nyt/HomePage.xmlawdjawiodj"))
;
; raises java.io.FileNotFoundException:
; http://www.nytimes.com/services/xml/rss/nyt/HomePage.xmlawdjawiodj
; (core.clj:7)
;
; Learn how to handle this exception later

; (keys f)
; (:authors :categories :contributors :copyright :description :encoding
; :entries :feed-type :image :language :link :entry-links
; :published-date :title :uri)

; (map (fn [e] (:title e))  (:entries f))

; make another namespace for persistence?


