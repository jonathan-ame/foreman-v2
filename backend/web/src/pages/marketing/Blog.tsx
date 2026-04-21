import { Link } from "react-router-dom";
import { posts } from "../../data/blogPosts";

export function Blog() {
  return (
    <>
      <section className="page-hero">
        <div className="content-inner text-center">
          <h1>Blog</h1>
          <p>Building in public. Lessons from running an AI-native business.</p>
        </div>
      </section>

      <section className="prose-section">
        <div className="content-inner content-narrow">
          {posts.length === 0 && (
            <p className="muted text-center">
              Posts coming soon. Follow along on LinkedIn for real-time updates.
            </p>
          )}
          <div className="blog-post-list">
            {posts.map((post) => (
              <article key={post.slug} className="blog-post-card">
                <Link to={`/blog/${post.slug}`} className="blog-post-link">
                  <h2 className="blog-post-title">{post.title}</h2>
                </Link>
                <p className="blog-post-meta">
                  {new Date(post.date).toLocaleDateString("en-US", {
                    year: "numeric",
                    month: "long",
                    day: "numeric",
                  })}
                  {post.tags.length > 0 && (
                    <>
                      {" · "}
                      {post.tags.map((tag) => (
                        <span key={tag} className="blog-post-tag">
                          {tag}
                        </span>
                      ))}
                    </>
                  )}
                </p>
                <p className="blog-post-excerpt">{post.excerpt}</p>
                <Link to={`/blog/${post.slug}`} className="blog-read-more">
                  Read more →
                </Link>
              </article>
            ))}
          </div>
        </div>
      </section>
    </>
  );
}
