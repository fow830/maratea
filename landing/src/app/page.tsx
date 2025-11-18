export default function HomePage() {
  const appUrl = process.env.APP_URL || 'http://localhost:3000';

  return (
    <main>
      <h1>Maratea - Корпоративное обучение</h1>
      <p>Онлайн-школа для корпоративных клиентов</p>
      <div>
        <a href={`${appUrl}/login`}>Войти</a>
        <a href={`${appUrl}/register`}>Регистрация</a>
      </div>
      <p>Landing page будет разработан в Фазе 5</p>
    </main>
  );
}
