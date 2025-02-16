;; based on microGUI and Win31 themes from sawfish WM

(local frame
  [{:background (load_image "themes/redmond/tl.png")
    :left-edge -4
    :top-edge -23
    :type :top-left-corner}

   {:background [(load_image "themes/redmond/title-inactive.png")
                 (load_image "themes/redmond/title.png")]
    :foreground [:000000 :ffffff]
    :text (fn [segment] segment.id)
    :text-x 4
    :text-y 0
    :top-edge -19
    :left-edge 19
    :right-edge 38
    :type :title}

   {:background (load_image "themes/redmond/t.png")
    :left-edge 19
    :right-edge 19
    :top-edge -23
    :type :top-border}
   
   {:background (load_image "themes/redmond/tr.png")
    :right-edge -4
    :top-edge -23
    :type :top-right-corner}
      
   {:background [(load_image "themes/redmond/menu.png")
                 (load_image "themes/redmond/menu.png")
                 (load_image "themes/redmond/menu-clicked.png")]
    :top-edge -19
    :left-edge 0
    :type :menu-button}
    
   {:background [(load_image "themes/redmond/min.png")
                 (load_image "themes/redmond/min.png")
                 (load_image "themes/redmond/min-clicked.png")]
    :right-edge 19
    :top-edge -19
    :type :iconify-button}
   
   {:background [(load_image "themes/redmond/max.png")
                 (load_image "themes/redmond/max.png")
                 (load_image "themes/redmond/max-clicked.png")]
    :right-edge 0
    :top-edge -19
    :type :maximize-button}

   {:background (load_image "themes/redmond/l.png")
    :right-edge -4
    :top-edge 0
    :bottom-edge 19
    :type :right-border}
   
   {:background (load_image "themes/redmond/br.png")
    :right-edge -4
    :bottom-edge -4
    :type :bottom-right-corner}
   
   {:background (load_image "themes/redmond/t.png")
    :left-edge 19
    :right-edge 19
    :bottom-edge -4
    :type :bottom-border}
   
   {:background (load_image "themes/redmond/bl.png")
    :left-edge -4
    :bottom-edge -4
    :type :bottom-left-corner}
   
   {:background (load_image "themes/redmond/l.png")
    :left-edge -4
    :top-edge 0
    :bottom-edge 19
    :type :left-border}])

{:name :redmond :frame frame :tabbed true}

