import { useAuthContext } from "../context/auth_context";

export const Home = () => {
  const { username, signedIn } = useAuthContext();

  return (
    <div>
      <h1>Welcome home, {signedIn ? username : "guest"}!</h1>
    </div>
  );
};
