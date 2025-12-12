"use client";

import { useState } from "react";

type CounterProps = {
  initialCount: number;
};

export default function Counter({ initialCount }: CounterProps) {
  const [count, setCount] = useState(initialCount);

  return (
    <div className="counter">
      <button
        onClick={() => setCount(count - 1)}
        className="counter-btn counter-btn-minus"
      >
        -
      </button>
      <span className="counter-value">{count}</span>
      <button
        onClick={() => setCount(count + 1)}
        className="counter-btn counter-btn-plus"
      >
        +
      </button>
    </div>
  );
}
