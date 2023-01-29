import { useState } from "react";
import { Link } from "react-router-dom";

export const Password = () => {
  const [password, setPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");
  const [errors, setErrors] = useState(null);
  const [success, setSuccess] = useState(false);

  const resetFields = () => {
    setErrors(null);
    setPassword("");
    setConfirmPassword("");
  };

  const reset = () => {
    resetFields();
    setSuccess(false);
  };

  const deletePassword = () => {
    if (
      window.confirm(
        "Are you sure? This will close all your currently opened ssh sessions."
      )
    ) {
      fetch(`/api/player/token/password`, {
        method: "DELETE",
        credentials: "same-origin",
      })
        .then((r) => r.json())
        .then((r) => {
          if (r.success) {
            resetFields();
            setSuccess(true);
          }
        });
    }
  };

  const submitPassword = () => {
    if (
      window.confirm(
        "Are you sure? This will close all your current ssh sessions."
      )
    ) {
      fetch(`/api/player/token/password`, {
        method: "PUT",
        credentials: "same-origin",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          password,
          password_confirmation: confirmPassword,
        }),
      })
        .then((r) => r.json())
        .then((p) => {
          if (p.success) {
            resetFields();
            setSuccess(true);
          } else if (p.errors) {
            if (typeof p.errors === "object") {
              setErrors(
                Object.keys(p.errors).map(
                  (field) => `${field}: ${p.errors[field].join(",")}`
                )
              );
            } else {
              setErrors([p.errors]);
            }
          }
        });
    }
  };

  return (
    <>
      <div>
        <h3>Update SSH Password</h3>
        <p>
          An SSH password allows you to connect from any device. However, it is
          inherently less secure than a <Link to="/keys">public key</Link>.
        </p>
        <p>Use a password at your own risk.</p>
      </div>
      <hr />
      <div>
        <h4> Previously set a password and no longer want it? </h4>
        <button className="button red" onClick={deletePassword}>
          Delete Password
        </button>
      </div>
      <div>
        <h4>Or if you're dead set on it...</h4>
        <div>
          <p>Password *</p>
          <input
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            type="password"
            required
          />
        </div>
        <div>
          <p>Confirm Password *</p>
          <input
            value={confirmPassword}
            type="password"
            onChange={(e) => setConfirmPassword(e.target.value)}
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

        <div
          className="flex-end-row"
          style={{ justifyContent: "start", marginTop: "1rem" }}
        >
          <button className="button" onClick={submitPassword}>
            Submit
          </button>
          <button className="button gold" onClick={reset}>
            Reset Form
          </button>
        </div>
      </div>

      <br />
      <div>
        {success && <div style={{ color: "green" }}>Password updated</div>}
      </div>
    </>
  );
};
