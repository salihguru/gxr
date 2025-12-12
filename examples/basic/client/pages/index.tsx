import Header from "../components/Header";
import Counter from "../components/Counter";

type Props = {
  title: string;
  initialCount: number;
};

export default function Index(props: Props) {
  return (
    <html lang="en">
      <head>
        <meta charSet="UTF-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1.0" />
        <title>{props.title}</title>
        <style dangerouslySetInnerHTML={{ __html: `
          * {
            box-sizing: border-box;
            margin: 0;
            padding: 0;
          }
          
          body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
          }
          
          .container {
            background: white;
            border-radius: 16px;
            padding: 48px;
            box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.25);
            text-align: center;
            max-width: 400px;
          }
          
          .header h1 {
            font-size: 2.5rem;
            color: #1a202c;
            margin-bottom: 8px;
          }
          
          .header p {
            color: #718096;
            margin-bottom: 32px;
          }
          
          .counter {
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 16px;
          }
          
          .counter-btn {
            width: 48px;
            height: 48px;
            border: none;
            border-radius: 12px;
            font-size: 24px;
            font-weight: bold;
            cursor: pointer;
            transition: transform 0.1s, box-shadow 0.1s;
          }
          
          .counter-btn:hover {
            transform: scale(1.05);
          }
          
          .counter-btn:active {
            transform: scale(0.95);
          }
          
          .counter-btn-minus {
            background: #fc8181;
            color: white;
          }
          
          .counter-btn-plus {
            background: #68d391;
            color: white;
          }
          
          .counter-value {
            font-size: 3rem;
            font-weight: bold;
            min-width: 80px;
            color: #2d3748;
          }
          
          .footer {
            margin-top: 32px;
            padding-top: 24px;
            border-top: 1px solid #e2e8f0;
            color: #a0aec0;
            font-size: 0.875rem;
          }
          
          .footer code {
            background: #edf2f7;
            padding: 2px 6px;
            border-radius: 4px;
            font-family: monospace;
          }
        ` }} />
      </head>
      <body>
        <div className="container">
          <Header title={props.title} />
          
          <Counter initialCount={props.initialCount} />
          
          <footer className="footer">
            <p>
              This counter is a <code>"use client"</code> component.
              <br />
              It's hydrated automatically by GXR.
            </p>
          </footer>
        </div>
      </body>
    </html>
  );
}
