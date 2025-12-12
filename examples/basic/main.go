package main

import (
	"fmt"
	"net/http"

	gxr "github.com/salihguru/gxr-go"
)

func main() {
	// Create GXR instance
	g, err := gxr.NewWithOptions(gxr.Options{
		PublicPath: "/public",
		SourceDir:  "./",
	})
	if err != nil {
		panic(err)
	}

	// Serve static files
	http.Handle("/public/", http.StripPrefix("/public/", http.FileServer(http.Dir("public"))))

	// Handle main page
	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		html, err := g.Render("./client/pages/index.tsx", map[string]interface{}{
			"title":        "GXR Example",
			"initialCount": 0,
		})
		if err != nil {
			fmt.Println("Error rendering page:", err)
			http.Error(w, "Internal Server Error", http.StatusInternalServerError)
			return
		}

		w.Header().Set("Content-Type", "text/html")
		w.Write([]byte(html))
	})

	fmt.Println("🚀 Server running at http://localhost:8080")
	if err := http.ListenAndServe(":8080", nil); err != nil {
		panic(err)
	}
}
