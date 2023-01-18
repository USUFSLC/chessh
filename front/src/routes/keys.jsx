import { useEffect, useState } from "react";
import { useAuthContext } from "../context/auth_context";

const MINIMIZE_KEY_LEN = 40;
const minimizeKey = (key) => {
  const n = key.length;
  if (n >= MINIMIZE_KEY_LEN) {
    const half = Math.floor(MINIMIZE_KEY_LEN / 2);
    return key.substring(0, half) + "..." + key.substring(n - half, n);
  }
  return key;
};

const KeyCard = ({ props }) => {
  const { id, name, key } = props;

  const deleteThisKey = () => {
    fetch(`/api/keys/${id}`, {
      credentials: "same-origin",
      method: "DELETE",
    })
      .then((r) => r.json())
      .then((d) => d.success); //&& onDelete());
  };

  return (
    <div className="key-card">
      <h4>{name}</h4>
      <p>{minimizeKey(key)}</p>

      <button className="button red" onClick={deleteThisKey}>
        Delete
      </button>
    </div>
  );
};

const AddKey = () => {
  const [key, setKey] = useState("");
  const [name, setName] = useState("");
  const [error, setError] = useState("");

  const createKey = () => {
    fetch(`/api/player/keys`, {
      credentials: "same-origin",
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        key,
        name,
      }),
    })
      .then((r) => r.json())
      .then((d) => {
        if (d.success) {
          setName("");
          setKey("");
        } else {
          setError(d.errors);
        }
      });
  };

  return (
    <div className="key-card">
      <input onChange={(e) => setName(e.target.value)} />
      <textarea onChange={(e) => setKey(e.target.value)} />
      <button className="button gold" onClick={createKey}>
        Add
      </button>
    </div>
  );
};

export const Keys = () => {
  const { userId } = useAuthContext();
  const [keys, setKeys] = useState(null);

  useEffect(() => {
    if (userId) {
      fetch(`/api/player/${userId}/keys`)
        .then((r) => r.json())
        .then((keys) => setKeys(keys));
    }
  }, [userId]);

  if (!keys) {
    return <p>Loading...</p>;
  }
  if (Array.isArray(keys)) {
    return (
      <>
        <AddKey />
        {keys.length ? (
          keys.map((key) => <KeyCard key={key.id} props={key} />)
        ) : (
          <p>No keys</p>
        )}
      </>
    );
  }
};
