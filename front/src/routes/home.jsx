import { useAuthContext } from "../context/auth_context";

export const Home = () => {
  const { username } = useAuthContext();

  return (
    <div>
      <h1>Welcome home, {username || "guest"}!</h1>
    </div>
  );
};
