import Modal from "react-modal";
import { useEffect, useState, useCallback } from "react";
import { useAuthContext } from "../context/auth_context";

Modal.setAppElement("#root");

const MINIMIZE_KEY_LEN = 40;
const minimizeKey = (key) => {
  const n = key.length;
  if (n >= MINIMIZE_KEY_LEN) {
    const half = Math.floor(MINIMIZE_KEY_LEN / 2);
    return key.substring(0, half) + "..." + key.substring(n - half, n);
  }
  return key;
};

const KeyCard = ({ onDelete, props }) => {
  const { id, name, key } = props;

  const deleteThisKey = () => {
    fetch(`/api/keys/${id}`, {
      credentials: "same-origin",
      method: "DELETE",
    })
      .then((r) => r.json())
      .then((d) => d.success && onDelete && onDelete());
  };

  return (
    <div className="key-card">
      <h4 style={{ flex: 1 }}>{name}</h4>
      <p style={{ flex: 4 }}>{minimizeKey(key)}</p>

      <button
        style={{ flex: 0 }}
        className="button red"
        onClick={deleteThisKey}
      >
        Delete
      </button>
    </div>
  );
};

const AddKeyButton = ({ onSave }) => {
  const [open, setOpen] = useState(false);
  const [name, setName] = useState({ value: "", error: "" });
  const [key, setKey] = useState({ value: "", error: "" });
  const [errors, setErrors] = useState(null);

  const setDefaults = () => {
    setName({ value: "", error: "" });
    setKey({ value: "", error: "" });
    setErrors(null);
  };

  const close = () => {
    setDefaults();
    setOpen(false);
  };

  const createKey = () => {
    fetch(`/api/player/keys`, {
      credentials: "same-origin",
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        key: key.value.trim(),
        name: name.value,
      }),
    })
      .then((r) => r.json())
      .then((d) => {
        if (d.success) {
          if (onSave) {
            onSave();
          }
          close();
        } else if (d.errors) {
          if (typeof d.errors === "object") {
            setErrors(
              Object.keys(d.errors).map(
                (field) => `${field}: ${d.errors[field].join(",")}`
              )
            );
          } else {
            setErrors([d.errors]);
          }
        }
      });
  };

  return (
    <div>
      <button className="button" onClick={() => setOpen(true)}>
        + Add Key
      </button>
      <Modal
        isOpen={open}
        onRequestClose={close}
        className="modal"
        contentLabel="Add Key"
      >
        <div>
          <h3>Add SSH Key</h3>
          <p>
            Not sure about this? Check{" "}
            <a
              href="https://www.ssh.com/academy/ssh/keygen"
              target="_blank"
              rel="noreferrer"
            >
              here
            </a>{" "}
            for help!
          </p>
          <hr />
          <p>Key Name *</p>
          <input
            value={name.value}
            onChange={(e) => setName({ ...name, value: e.target.value })}
            required
          />
        </div>
        <div>
          <p>SSH Key *</p>
          <textarea
            cols={40}
            rows={5}
            value={key.value}
            onChange={(e) => setKey({ ...key, value: e.target.value })}
            required
          />
        </div>
        <div>
          {errors && (
            <div style={{ color: "red" }}>
              {errors.map((error, i) => (
                <p key={i}>{error}</p>
              ))}
            </div>
          )}
        </div>
        <div className="flex-end-row">
          <button className="button" onClick={createKey}>
            Add
          </button>
          <button className="button red" onClick={close}>
            Cancel
          </button>
        </div>
      </Modal>
    </div>
  );
};

export const Keys = () => {
  const {
    player: { id: userId },
  } = useAuthContext();
  const [keys, setKeys] = useState(null);

  const refreshKeys = useCallback(
    () =>
      fetch(`/api/player/${userId}/keys`)
        .then((r) => r.json())
        .then((keys) => setKeys(keys)),
    [userId]
  );

  useEffect(() => {
    if (userId) {
      refreshKeys();
    }
  }, [userId, refreshKeys]);

  if (!keys) return <p>Loading...</p>;

  if (Array.isArray(keys)) {
    return (
      <>
        <h2>My Keys</h2>
        <AddKeyButton onSave={refreshKeys} />
        <div className="key-card-collection">
          {keys.length ? (
            keys.map((key) => (
              <KeyCard key={key.id} onDelete={refreshKeys} props={key} />
            ))
          ) : (
            <p>Looks like you've got no keys, try adding some!</p>
          )}
        </div>
      </>
    );
  }
};
