import './globals.css'
import Counter from '@/components/Counter'
import Header from '@/components/Header'

export default function Home() {
  return (
    <main className="container">
      <Header title="GXR Basic Example" />
      <Counter initialCount={0} />
      <div className="tech-stack">
        <h3>Built with</h3>
        <div className="tech-badges">
          <span className="badge badge-go">Next.js</span>
          <span className="badge badge-react">React 19</span>
          <span className="badge badge-typescript">TypeScript</span>
        </div>
      </div>
    </main>
  )
}
