import Modal from "react-modal";
import { useAuthContext } from "../context/auth_context";
import { useEffect, useState, useCallback } from "react";

Modal.setAppElement("#root");

const BotButton = ({ onSave, givenBot }) => {
  const [open, setOpen] = useState(false);
  const [name, setName] = useState(givenBot?.name || "");
  const [webhook, setWebhook] = useState(givenBot?.webhook || "");
  const [errors, setErrors] = useState(null);
  const [isPublic, setIsPublic] = useState(givenBot?.public || false);

  const setDefaults = () => {
    setName("");
    setWebhook("");
    setErrors(null);
  };

  const close = () => {
    if (!givenBot) {
      setDefaults();
    }
    setOpen(false);
  };

  const updateBot = () => {
    fetch(givenBot ? `/api/player/bots/${givenBot.id}` : "/api/player/bots", {
      credentials: "same-origin",
      method: givenBot ? "PUT" : "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        webhook: webhook.trim(),
        name: name.trim(),
        public: isPublic,
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
        {givenBot ? "Update" : "+ Add"} Bot
      </button>
      {givenBot && (
        <>
          <button
            style={{ marginLeft: "1rem" }}
            className="button gold"
            onClick={() => {
              navigator.clipboard.writeText(givenBot?.token);
              alert("Bot's token was copied to the clipboard.");
            }}
          >
            Copy Token
          </button>
          <button
            style={{ marginLeft: "1rem" }}
            className="button red"
            onClick={() =>
              fetch(`/api/player/bots/${givenBot.id}/redrive`)
                .then((r) => r.json())
                .then(({ message }) => alert(message))
            }
          >
            Schedule Redrive
          </button>
        </>
      )}
      <Modal
        isOpen={open}
        onRequestClose={close}
        className="modal"
        contentLabel="Add Bot"
      >
        <div style={{ minWidth: "20vw" }}>
          <h3>Add Bot</h3>
          <hr />
          <p>Bot Name *</p>
          <input
            style={{ width: "100%" }}
            value={name}
            onChange={(e) => setName(e.target.value)}
            required
          />
        </div>
        <div>
          <p>Webhook *</p>
          <input
            style={{ width: "100%" }}
            value={webhook}
            onChange={(e) => setWebhook(e.target.value)}
            required
          />
        </div>
        <p>
          Public *{" "}
          <input
            type="checkbox"
            value={name}
            checked={isPublic}
            onChange={(e) => setIsPublic(!isPublic)}
            required
          />
        </p>
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
          <button className="button" onClick={updateBot}>
            {givenBot ? "Update" : "+ Add"}
          </button>
          <button className="button red" onClick={close}>
            Cancel
          </button>
        </div>
      </Modal>
    </div>
  );
};

export const BotCard = ({ botStruct, onSave }) => {
  const { name, token } = botStruct;
  return (
    <div className="key-card">
      <h4>{name}</h4>
      <BotButton onSave={onSave} givenBot={botStruct} />
    </div>
  );
};

export const Bots = () => {
  const {
    player: { id: userId },
  } = useAuthContext();
  const [bots, setBots] = useState(null);

  const refreshBots = () =>
    fetch("/api/player/bots")
      .then((r) => r.json())
      .then((bots) => setBots(bots));

  useEffect(() => {
    if (userId) {
      refreshBots();
    }
  }, [userId]);

  if (bots === null) return <p>Loading...</p>;

  return (
    <>
      <h1>Bots</h1>
      <BotButton onSave={refreshBots} />

      <div className="key-card-collection">
        {bots.length ? (
          bots.map((bot) => (
            <BotCard key={bot.id} onSave={refreshBots} botStruct={bot} />
          ))
        ) : (
          <p>Looks like you've got no bots, try adding one!</p>
        )}
      </div>
    </>
  );
};
