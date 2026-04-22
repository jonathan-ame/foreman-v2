import { useEffect } from "react";
import { useParams, Link, Navigate } from "react-router-dom";
import { getPostBySlug } from "../../data/blogPosts";
import { renderMarkdown } from "../../utils/markdown";
import { trackEvent } from "../../utils/analytics";

export function BlogPost() {
  const { slug } = useParams<{ slug: string }>();
  const post = slug ? getPostBySlug(slug) : undefined;

  useEffect(() => {
    if (post) {
      const metaDesc = post.metaDescription ?? post.excerpt;
      document.title = `${post.title} — Foreman Blog`;
      setMeta("description", metaDesc);
      setMeta("og:title", post.title);
      setMeta("og:description", metaDesc);
      setMeta("og:url", `https://foreman.company/blog/${post.slug}`);
      setMeta("og:type", "article");
      setMeta("article:published_time", post.date);
      setMeta("article:author", post.author);
      for (const tag of post.tags) {
        addMeta("article:tag", tag);
      }
      if (post.metaKeywords) {
        setMeta("keywords", post.metaKeywords);
      }
      setMeta("twitter:card", "summary_large_image");
      setMeta("twitter:title", post.title);
      setMeta("twitter:description", metaDesc);
      if (post.image) {
        const imageUrl = new URL(post.image, window.location.origin).href;
        setMeta("og:image", imageUrl);
        setMeta("twitter:image", imageUrl);
      }
    }
    return () => {
      document
        .querySelectorAll('meta[property="article:tag"]')
        .forEach((el) => el.remove());
    };
  }, [post]);

  useEffect(() => {
    if (!post) return;
    const handler = (e: MouseEvent) => {
      const target = e.target as HTMLElement;
      if (target.tagName !== "A") return;
      const href = (target as HTMLAnchorElement).href;
      if (href.includes("utm_source=case_study")) {
        trackEvent("blog_post_viewed" as "page_view", {
          cta_click: "case_study_waitlist",
          post_slug: post.slug,
        });
      }
    };
    document.addEventListener("click", handler);
    return () => document.removeEventListener("click", handler);
  }, [post]);

  if (!post) {
    return <Navigate to="/blog" replace />;
  }

  const html = renderMarkdown(post.body);

  return (
    <>
      <section className="page-hero">
        <div className="content-inner text-center">
          <h1>{post.title}</h1>
          <p>
            {new Date(post.date).toLocaleDateString("en-US", {
              year: "numeric",
              month: "long",
              day: "numeric",
            })}{" "}
            · {post.author}
          </p>
        </div>
      </section>

      <section className="prose-section">
        <div className="content-inner content-narrow">
          <div
            className="blog-post-body"
            dangerouslySetInnerHTML={{ __html: html }}
          />
          {post.tags.length > 0 && (
            <div className="blog-post-tags">
              {post.tags.map((tag) => (
                <span key={tag} className="blog-post-tag">
                  {tag}
                </span>
              ))}
            </div>
          )}
          <div className="blog-post-nav">
            <Link to="/blog" className="blog-back-link">
              ← Back to blog
            </Link>
          </div>
        </div>
      </section>
    </>
  );
}

function setMeta(property: string, content: string) {
  const isOg = property.startsWith("og:") || property === "type";
  const attr = isOg ? "property" : "name";
  let el = document.querySelector(`meta[${attr}="${property}"]`);
  if (!el) {
    el = document.createElement("meta");
    el.setAttribute(attr, property);
    document.head.appendChild(el);
  }
  el.setAttribute("content", content);
}

function addMeta(property: string, content: string) {
  const el = document.createElement("meta");
  el.setAttribute("property", property);
  el.setAttribute("content", content);
  document.head.appendChild(el);
}
