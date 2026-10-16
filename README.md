# Gymventory

Dziennik treningowy jako aplikacja webowa (PWA). Instaluje się na telefonie i komputerze jak zwykła aplikacja i działa offline na siłowni. Każda osoba ma własne konto. Znajomi mogą podglądać swoje treningi, trenować to samo i rzucać sobie wyzwania.

Pierwsza konfiguracja zajmuje około 15 minut. Potrzebujesz dwóch darmowych kont: **Supabase** (baza danych i zdjęcia) oraz **GitHub** (hosting).

---

## 1. Baza danych — Supabase

1. Wejdź na **supabase.com** → *Start your project* i załóż konto (najszybciej przez „Continue with GitHub”).
2. Kliknij **New project**:
   - Name: `gymventory`
   - Database Password: wygeneruj i zapisz (aplikacja go nie potrzebuje)
   - Region: **Central EU (Frankfurt)**
   - Kliknij *Create new project* i poczekaj 1–2 minuty.
3. Otwórz **SQL Editor** → *New query*. Wklej **całą** zawartość pliku `gymventory.sql` i kliknij **Run**. Powinieneś zobaczyć „Success. No rows returned”.
   Skrypt tworzy tabele, reguły bezpieczeństwa i prywatny schowek na zdjęcia. Można go bezpiecznie uruchomić ponownie, np. po aktualizacji.
4. Otwórz **Authentication → Sign In / Providers → Email** i wyłącz **„Confirm email”** → *Save*. Konta zakłada się wtedy od razu, bez klikania w link z e-maila.
5. Otwórz **Project Settings → Data API** i skopiuj **Project URL**. Potem w **API Keys** skopiuj klucz **anon public** (albo **Publishable key**).
   **Nigdy nie używaj klucza `service_role` / `secret`.**

## 2. Hosting — GitHub Pages

1. Na **github.com** kliknij **+ → New repository**. Nazwa: `gymventory`, zaznacz **Public**, potem *Create repository*.
2. Kliknij **uploading an existing file** i przeciągnij **zawartość** tego folderu (pliki i folder `icons`) → *Commit changes*.
3. Otwórz **config.js** → ołówek (*Edit*). Wklej swój Project URL i klucz w miejsce `TWOJ_PROJECT_URL` i `TWOJ_ANON_KEY` → *Commit changes*.
4. Przejdź do **Settings → Pages** i ustaw: *Deploy from a branch*, branch **main**, folder **/ (root)** → *Save*.
5. Po 1–2 minutach aplikacja działa pod adresem **`https://TWOJLOGIN.github.io/gymventory/`**.

> Jeśli połączysz GitHub z Claude, kroki 2–3 i wszystkie kolejne aktualizacje Claude może robić za Ciebie.

## 3. Instalacja i konta

- **Android (Chrome):** menu ⋮ → **Zainstaluj aplikację**.
- **iPhone (Safari):** *Udostępnij* → **Do ekranu początkowego**.
- **Komputer (Chrome / Edge):** ikona instalacji w pasku adresu.

Każda osoba otwiera ten sam adres i w **Więcej → Konto** wybiera **Załóż konto**. Dane każdego są oddzielne.
Na kolejnych własnych urządzeniach używasz **Zaloguj się** z tym samym e-mailem i hasłem.

> Gdy wszyscy znajomi założą już konta, możesz zablokować nowe rejestracje: *Authentication → Sign In / Providers → Allow new users to sign up* → wyłącz.

## 4. Znajomi i wyzwania (zakładka Ekipa)

- Każdy ma 6-znakowy **kod**. Wpisz kod znajomego → **Dodaj**. On akceptuje zaproszenie u siebie.
- Znajomi widzą Twoje treningi (ćwiczenia, serie, ciężary). **Nie widzą** notatek, zdjęć ani masy ciała. Udostępnianie wyłączysz przełącznikiem w zakładce Ekipa.
- W zakładce **Trening** widać, kto ze znajomych trenował tego samego dnia. Przycisk **Trenuj to samo dziś** kopiuje jego ćwiczenia do Twojego treningu, a ciężary wpisują się z Twojej historii.
- **Wyzwania:** najwięcej treningów, serii, objętości, powtórzeń lub największy ciężar w danym ćwiczeniu, kilometry cardio. Każdy uczestnik liczy swój wynik automatycznie, a tabela wyników aktualizuje się po treningu.
  W wyzwaniach na konkretne ćwiczenie liczy się ćwiczenie o tej samej nazwie u każdego uczestnika.

## Przeniesienie danych z wcześniejszej wersji

W poprzedniej wersji (link w Claude) wejdź w **Więcej → Kopia zapasowa**. W Gymventory kliknij **Więcej → Importuj dane** i wskaż ten plik.
Import przyjmuje też pliki CSV z innych aplikacji treningowych i arkuszy.

---

## Dobrze wiedzieć

- **Uśpienie projektu:** darmowy projekt Supabase usypia się po około tygodniu bez **żadnej** aktywności (wystarczy, że ktokolwiek z ekipy otworzy aplikację). Jeśli do tego dojdzie, aplikacja dalej działa offline, a w panelu Supabase wystarczy kliknąć **Restore project**.
- **Miejsce:** darmowy plan mieści ok. 500 MB danych i 1 GB zdjęć. Zdjęcia są zmniejszane do ok. 150–250 kB, więc to tysiące zdjęć.
- **Kopia zapasowa:** co jakiś czas zrób **Więcej → Kopia zapasowa**.
- **Prywatność:** reguły w `gymventory.sql` pilnują, żeby każdy widział tylko swoje dane, a znajomi wyłącznie udostępnione treningi i wspólne wyzwania.
- **Aktualizacje:** po podmianie plików zmień numer `VERSION` w `sw.js`. Urządzenia pobiorą nową wersję w tle i pokażą ją przy następnym otwarciu.

## Pliki

| Plik | Do czego służy |
|---|---|
| `index.html` | cała aplikacja |
| `config.js` | adres i klucz Twojego projektu Supabase |
| `gymventory.sql` | tabele, reguły bezpieczeństwa i schowek na zdjęcia (uruchamiasz w Supabase) |
| `sw.js` | działanie offline i aktualizacje |
| `manifest.webmanifest`, `icons/` | instalacja jako aplikacja, ikony |
