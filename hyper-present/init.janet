(import spork/httpf)
(import spork/htmlgen)
(import ./parser)

(var <o> nil)

(defn >>>
  "Process command"
  [key & args]
  (ev/give-supervisor key ;args))

(defn supervise
  "Function for web supervisor"
  [store]
  (fn [channel]
    (eprint "Supervisor is running")
    (forever
      (match (ev/take channel)
        [:next-slide]
        (let [{:chapter chapter :slide slide :presentation {:chapters chapters}} store
              current-chapter (chapters chapter)]
          (if (< (inc slide) (length (current-chapter :slides)))
            (update store :slide inc)))
        [:previous-slide]
        (let [{:chapter chapter :slide slide :presentation {:chapters chapters}} store
              current-chapter (chapters chapter)]
          (if (>= (dec slide) 0)
            (update store :slide dec)))
        [:next-chapter]
        (let [{:chapter chapter :presentation {:chapters chapters}} store]
          (when (< (inc chapter) (length chapters))
            (update store :chapter inc)
            (put store :slide 0)))
        [:previous-chapter]
        (let [{:chapter chapter} store]
          (when (>= (dec chapter) 0)
            (update store :chapter dec)
            (put store :slide 0)))))))

(def View
  "View prototype"
  @{:title (fn [{:_store {:presentation presentation}}] (presentation :title))
    :slide-title (fn [{:_store {:chapter chapter :slide slide :presentation {:chapters chapters}}}]
                   (htmlgen/raw (string (get-in chapters [chapter :title]) " #" (inc slide))))
    :current-slide (fn [{:_store {:chapter chapter :slide slide :presentation {:chapters chapters}}}]
                     @[(get-in chapters [chapter :slides slide])
                       [:small {:class "width:100% justify-content:end f-row fixed bottom padding-block-end"}
                        (get-in chapters [chapter :date])]])})

(defn /index
  "Root route"
  {:path "/"}
  [_ _]
  @[htmlgen/doctype-html
    [:html {"lang" "en"}
     [:head
      [:meta {"charset" "UTF-8"}]
      [:meta {"name" "viewport"
              "content" "width=device-width, initial-scale=1.0"}]
      [:meta {"name" "description"
              "content" (string "Hyper Present - " (:title <o>))}]
      [:title "Hyper Present"]
      [:link {:rel "stylesheet" :href "https://unpkg.com/missing.css@1.1.1"}]
      [:style ``
              :root {font-size: 48px} 
              nav {z-index: 1; transition: opacity 250ms ease-in-out; font-size: 0.5rem}
              small {font-size: 0.5rem}
              ``]]
     [:body
      {:_
       ``
        on keyup
          set k to the event's key
          if k is 'ArrowRight' or k is ' ' send next to <nav div[data-role='slide'] a/>
          else if k is 'ArrowLeft' send previous to <nav div[data-role='slide'] a/>
          else if k is 'ArrowDown' send next to <nav div[data-role='chapter'] a/>
          else if k is 'ArrowUp' send previous to <nav div[data-role='chapter'] a/>
        ``}
      [:nav {:class "width:100% fixed f-row justify-content:space-between padding-inline align-items:baseline"
             :hx-swap "none"
             :_ ``
                init wait 1s then hide me with *opacity
                on mouseenter or refresh set :hidding to false then show me with *opacity
                on mouseleave or refresh
                  set :hidding to true
                  wait 1s 
                  if :hidding 
                    hide me with *opacity
                    set :hidding to false
                  end 
                ``}
       [:div {:data-role "slide"}
        [:a {:hx-trigger "click, previous" :hx-get "/previous-slide"} "<"]
        [:small " slide "]
        [:a {:hx-trigger "click, next" :hx-get "/next-slide"} ">"]]
       [:small {:hx-get "/slide-title" :hx-swap "innerHtml" :hx-trigger "load, click, refresh from:body"}]
       [:div {:data-role "chapter"}
        [:a {:hx-trigger "click, previous" :hx-get "/previous-chapter"} "\u00AB"]
        [:small " chapter "]
        [:a {:hx-trigger "click, next" :hx-get "/next-chapter"} "\u00BB"]]]
      [:main {:class "f-col fullscreen justify-content:center"
              :hx-get "/current-slide" :hx-trigger "load, click, refresh from:body"}]
      [:script {:src "https://unpkg.com/hyperscript.org@0.9.11"}]
      [:script {:src "https://unpkg.com/htmx.org@1.9.6"}]]]])

(defn trigger-header
  [header]
  (put (dyn :response-headers) :HX-Trigger header)
  "")

(defn /next-slide
  "Switch to next slide"
  {:path "/next-slide"}
  [&]
  (>>> :next-slide)
  (trigger-header "refresh"))

(defn /previous-slide
  "Switch to previous slide"
  {:path "/previous-slide"}
  [&]
  (>>> :previous-slide)
  (trigger-header "refresh"))

(defn /next-chapter
  "Switch to next chapter"
  {:path "/next-chapter"}
  [&]
  (>>> :next-chapter)
  (trigger-header "refresh"))

(defn /previous-chapter
  "Switch to previous chapter"
  {:path "/previous-chapter"}
  [&]
  (>>> :previous-chapter)
  (trigger-header "refresh"))

(defn /slide-title
  "Renders slide title"
  {:path "/slide-title"}
  [&] (:slide-title <o>))

(defn /current-slide
  "Renders current slide"
  {:path "/current-slide"}
  [&]
  (:current-slide <o>))

(def- web-server "Template server" (httpf/server))
(httpf/add-bindings-as-routes web-server)

(defn web-listener
  "Function for creating web server fiber."
  [ip port]
  (fn [ws]
    (eprin "HTTP server is ")
    (httpf/listen ws ip port 1)))

(defn main [_ presentation]
  (def store @{:presentation (parser/parse-string (slurp presentation))
               :chapter 0 :slide 0 :connections @[]})
  (set <o> (table/setproto @{:_store store} View))
  (def supervisor (ev/chan 1024))
  (ev/go (supervise store) supervisor)
  (ev/go (web-listener "127.0.0.1" "8000") web-server supervisor))
