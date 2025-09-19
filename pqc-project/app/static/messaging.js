document.addEventListener('DOMContentLoaded', () => {
    // --- DOM Elements ---
    const messageDisplay = document.getElementById('message-display');
    const messageForm = document.getElementById('message-form');
    const messageInput = document.getElementById('message-input');
    const recipientInput = document.getElementById('recipient-input');
    const currentUserDisplay = document.getElementById('current-user-display');

    // --- State ---
    let currentUser = '';
    const selectedUser = 'gitgud'; // Hardcoded recipient
    let messagePollingInterval;

    // --- API Functions ---
    async function fetchCurrentUser() {
        const response = await fetch('/api/get_current_user');
        const data = await response.json();
        currentUser = data.username;
        // The display for the current user is now hardcoded in the HTML,
        // but we can update something else if needed, or just leave this as is.
        // currentUserDisplay.textContent = currentUser;
    }

    async function fetchMessages() {
        const response = await fetch(`/api/get_messages?recipient=${selectedUser}`);
        const messages = await response.json();
        displayMessages(messages);
    }

    async function sendMessage(message) {
        if (!message) return;

        // Play the sound effect
        const audio = new Audio('/static/audio/gitgud.mp3');
        const promise = audio.play();
        if (promise !== undefined) {
            promise.catch(error => {
                // Autoplay was prevented or the file doesn't exist.
                // This is a common browser security feature.
                console.warn("Audio playback failed. This can happen if the file is missing (add gitgud.mp3 to static/audio) or if the user hasn't interacted with the page yet.", error);
            });
        }

        await fetch('/api/send_message', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ recipient: selectedUser, message_text: message }),
        });
        messageInput.value = '';
        fetchMessages();
    }

    // --- UI Functions ---
    function displayMessages(messages) {
        messageDisplay.innerHTML = '';
        messages.slice().reverse().forEach(msg => {
            const msgDiv = document.createElement('div');
            msgDiv.classList.add('message');
            // To distinguish between user's messages and gitgud's
            if (msg.sender !== 'gitgud') {
                msgDiv.classList.add('sent');
                msgDiv.textContent = `You: ${msg.message_text}`;
            } else {
                msgDiv.classList.add('received');
                msgDiv.textContent = `gitgud: ${msg.message_text}`;
            }
            messageDisplay.appendChild(msgDiv);
        });
    }

    // --- Event Listeners ---
    messageForm.addEventListener('submit', (e) => {
        e.preventDefault();
        sendMessage(messageInput.value);
    });

    // --- Initialization ---
    async function init() {
        await fetchCurrentUser();
        fetchMessages(); // Initial fetch
        messagePollingInterval = setInterval(fetchMessages, 3000); // Poll for new messages
    }

    init();
});
