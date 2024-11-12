class PhotoGallery extends HTMLElement {
  constructor() {
    super();
    const shadow = this.attachShadow({ mode: "open" });

    const style = document.createElement("style");
    style.textContent = `
      .gallery-container {
        width: 90%;
        margin: 0 auto;
      }

      .gallery {
        column-count: 5; /* Fixed 5-column layout */
        column-gap: 0; /* No space between columns */
      }

      .gallery img {
        width: 100%;
        display: block;
        margin: 0;
        border-radius: 5px;
        cursor: pointer;
        transition: transform 0.2s;
        opacity: 0;
        transition: opacity 0.3s ease;
      }

      .gallery img.lazy-loaded {
        opacity: 1;
      }

      /* Responsive adjustments for smaller screens */
      @media (max-width: 1024px) {
        .gallery {
          column-count: 3;
        }
      }

      @media (max-width: 768px) {
        .gallery {
          column-count: 2;
        }
      }

      @media (max-width: 480px) {
        .gallery {
          column-count: 1;
        }
      }

      /* Lightbox styling */
      .lightbox {
        display: none;
        position: fixed;
        top: 0;
        left: 0;
        width: 100%;
        height: 100%;
        background: rgba(0, 0, 0, 0.9);
        justify-content: center;
        align-items: center;
        flex-direction: column;
        z-index: 1000;
      }

      .lightbox img {
        max-width: 90%;
        max-height: 80vh;
        margin-bottom: 1rem;
        border-radius: 5px;
      }

      .lightbox-controls {
        display: flex;
        gap: 20px;
      }

      .control-button {
        background: #fff;
        color: #000;
        padding: 0.5em 1em;
        font-size: 1rem;
        cursor: pointer;
        border-radius: 5px;
        border: none;
        transition: background 0.3s;
      }

      .control-button:focus,
      .control-button:hover {
        background: #eee;
      }
    `;

    const container = document.createElement("div");
    container.classList.add("gallery-container");

    const gallery = document.createElement("div");
    gallery.classList.add("gallery");

    // Lightbox container for displaying full-size images
    const lightbox = document.createElement("div");
    lightbox.classList.add("lightbox");
    lightbox.setAttribute("aria-hidden", "true");

    // Lightbox image
    const lightboxImage = document.createElement("img");
    lightbox.appendChild(lightboxImage);

    // Lightbox controls (Previous, Next, Close)
    const controls = document.createElement("div");
    controls.classList.add("lightbox-controls");

    const prevButton = document.createElement("button");
    prevButton.textContent = "Previous";
    prevButton.classList.add("control-button");
    prevButton.setAttribute("aria-label", "Previous image");

    const nextButton = document.createElement("button");
    nextButton.textContent = "Next";
    nextButton.classList.add("control-button");
    nextButton.setAttribute("aria-label", "Next image");

    const closeButton = document.createElement("button");
    closeButton.textContent = "Close";
    closeButton.classList.add("control-button");
    closeButton.setAttribute("aria-label", "Close lightbox");


    controls.append(prevButton, closeButton, nextButton);
    lightbox.appendChild(controls);

    container.appendChild(gallery);
    shadow.appendChild(style);
    shadow.appendChild(container);
    shadow.appendChild(lightbox);

    // Populate gallery with images from attributes
    const images = JSON.parse(this.getAttribute("images") || "[]");

    images.forEach((src, index) => {
      const img = document.createElement("img");
      img.setAttribute("data-src", `images/thumbnails/${src}`);
      img.setAttribute("data-full-src", `images/${src}`);
      img.setAttribute("data-index", index);
      img.alt = `Image ${index + 1}`;
      img.tabIndex = 0;
      img.classList.add("lazy");

      img.addEventListener("click", () => this.openLightbox(index));
      img.addEventListener("keypress", (e) => {
        if (e.key === "Enter") this.openLightbox(index);
      });

      gallery.appendChild(img);
    });

    // Lazy loading with IntersectionObserver
    const lazyLoad = (img) => {
      img.src = img.getAttribute("data-src");
      img.onload = () => {
        img.classList.add("lazy-loaded");
        img.removeAttribute("data-src");
      };
    };

    const observer = new IntersectionObserver(
      (entries, observer) => {
        entries.forEach((entry) => {
          if (entry.isIntersecting) {
            lazyLoad(entry.target);
            observer.unobserve(entry.target);
          }
        });
      },
      {
        rootMargin: "50px",
        threshold: 0.1,
      }
    );

    gallery.querySelectorAll("img").forEach((img) => observer.observe(img));

    let currentIndex = 0;

    this.openLightbox = (index) => {
      currentIndex = index;
      lightboxImage.src = '';
      lightbox.style.display = "flex";
      lightbox.setAttribute("aria-hidden", "false");
      closeButton.focus();

      setTimeout(() => {
        lightboxImage.src = gallery.children[currentIndex].getAttribute("data-full-src");
      }, 10);
    };

    this.closeLightbox = () => {
      lightbox.style.display = "none";
      lightbox.setAttribute("aria-hidden", "true");
    };

    this.showNextImage = () => {
      currentIndex = (currentIndex + 1) % images.length;
      preloadImage(currentIndex);
      lightboxImage.src = gallery.children[currentIndex].getAttribute("data-full-src");
    };

    this.showPreviousImage = () => {
      currentIndex = (currentIndex - 1 + images.length) % images.length;
      preloadImage(currentIndex);
      lightboxImage.src = gallery.children[currentIndex].getAttribute("data-full-src");
    };

    const preloadImage = (index) => {
      const img = new Image();
      img.src = gallery.children[index].getAttribute("data-full-src");
    };

    closeButton.addEventListener("click", this.closeLightbox);
    nextButton.addEventListener("click", this.showNextImage);
    prevButton.addEventListener("click", this.showPreviousImage);

    lightbox.addEventListener("click", (e) => {
      if (e.target === lightbox) this.closeLightbox();
    });

    lightbox.addEventListener("keydown", (e) => {
      if (e.key === "Escape") this.closeLightbox();
      if (e.key === "ArrowRight") this.showNextImage();
      if (e.key === "ArrowLeft") this.showPreviousImage();
    });
  }
}

customElements.define("photo-gallery", PhotoGallery);
