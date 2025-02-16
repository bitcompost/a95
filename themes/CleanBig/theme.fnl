;; based on CleanBig theme from sawfish WM

(local frame
  [{:background [(load_image "themes/CleanBig/title_bar_inactive.png")
                 (load_image "themes/CleanBig/title_bar_active.png")]
    :foreground [:000000 :ffffff]
    :text (fn [segment] segment.id)
    :text-x 4
    :text-y 0
    :top-edge -19
    :left-edge 16
    :right-edge 50
    :type :title}

   {:background [(load_image "themes/CleanBig/top_inactive.png")
                 (load_image "themes/CleanBig/top_active.png")]
    :top-edge -22
    :left-edge 16
    :right-edge 50
    :type :top-border}

   {:background [(load_image "themes/CleanBig/menu_inactive.png")]
                 ;(load_image "themes/CleanBig/menu_active.png")]
    :top-edge -22
    :left-edge -6
    :type :menu-button}

   {:background (load_image "themes/CleanBig/left.png")
    :left-edge -6
    :top-edge 0
    :bottom-edge 19
    :type :left-border}
   
   {:background (load_image "themes/CleanBig/top_right.png")
    :right-edge -6
    :top-edge -22
    :type :top-right-corner}

   {:background [(load_image "themes/CleanBig/top_right_button_box_inactive.png")
                 (load_image "themes/CleanBig/top_right_button_box_active.png")]
    :right-edge -3
    :top-edge -22
    :type :top-right-corner}

   {:background (load_image "themes/CleanBig/right.png")
    :right-edge -6
    :top-edge 0
    :bottom-edge 0
    :type :right-border}
    
   {:background (load_image "themes/CleanBig/bottom.png")
    :left-edge 17
    :right-edge 19
    :bottom-edge -6
    :type :bottom-border}
   
   {:background (load_image "themes/CleanBig/bottom_left.png")
    :left-edge -6
    :bottom-edge -6
    :type :bottom-left-corner}
    
   {:background (load_image "themes/CleanBig/bottom_right.png")
    :right-edge -6
    :bottom-edge -6
    :type :bottom-right-corner}

   {:background [(load_image "themes/CleanBig/minimize_active.png")
                 (load_image "themes/CleanBig/minimize_active.png")
                 (load_image "themes/CleanBig/minimize_clicked.png")]
    :right-edge 31
    :top-edge -19
    :type :iconify-button}

   {:background [(load_image "themes/CleanBig/maximize_active.png")
                 (load_image "themes/CleanBig/maximize_active.png")
                 (load_image "themes/CleanBig/maximize_clicked.png")]
    :right-edge 14
    :top-edge -19
    :type :maximize-button}

   {:background [(load_image "themes/CleanBig/close_normal.png")
                 (load_image "themes/CleanBig/close_normal.png")
                 (load_image "themes/CleanBig/close_clicked.png")]
    :right-edge -3
    :top-edge -19
    :type :close-button}])

{:name :CleanBig :frame frame :tabbed true}
