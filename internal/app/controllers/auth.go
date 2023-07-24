package controllers

import (
	"time"

	"github.com/gofiber/fiber/v2"
	"github.com/google/uuid"

	"github.com/shurco/litecart/internal/app/models"
	"github.com/shurco/litecart/internal/app/queries"
	"github.com/shurco/litecart/pkg/crypto"
	"github.com/shurco/litecart/pkg/jwtutil"
	"github.com/shurco/litecart/pkg/validator"
	"github.com/shurco/litecart/pkg/webutil"
)

func SignIn(q *queries.Base, j *jwtutil.Setting) fiber.Handler {
	return func(c *fiber.Ctx) error {
		request := new(models.SignIn)

		if err := c.BodyParser(request); err != nil {
			return webutil.StatusBadRequest(c, err)
		}

		if err := validator.Struct(request); err != nil {
			return webutil.StatusBadRequest(c, err)
		}

		passwordHash, err := q.GetPasswordByEmail(request.Email)
		if err != nil {
			return webutil.StatusBadRequest(c, err.Error())
		}

		compareUserPassword := crypto.ComparePasswords(passwordHash, request.Password)
		if !compareUserPassword {
			return webutil.StatusBadRequest(c, "wrong user email address or password")
		}

		// Generate a new pair of access and refresh tokens.
		userID := uuid.New()
		expires := time.Now().Add(time.Hour * time.Duration(j.SecretExpireHours)).Unix()
		token, err := jwtutil.GenerateNewToken(j.Secret, userID.String(), expires, nil)
		if err != nil {
			return webutil.Response(c, fiber.StatusInternalServerError, "Internal server error", err.Error())
		}

		// Add session record
		if err := q.AddSession(userID.String(), "admin", expires); err != nil {
			return webutil.Response(c, fiber.StatusInternalServerError, "Failed to save token", err.Error())
		}

		c.Cookie(&fiber.Cookie{
			Name:    "token",
			Value:   token,
			Expires: time.Now().Add(24 * time.Hour),
			//HTTPOnly: true,
			SameSite: "lax",
		})

		return webutil.StatusOK(c, "Token", token)
	}
}

func SignOut(q *queries.Base, secret string) fiber.Handler {
	return func(c *fiber.Ctx) error {
		claims, err := jwtutil.ExtractTokenMetadata(c, secret)
		if err != nil {
			return webutil.Response(c, fiber.StatusInternalServerError, "Internal server error", err.Error())
		}

		if err := q.DeleteSession(claims.ID); err != nil {
			return webutil.Response(c, fiber.StatusInternalServerError, "Failed to delete token", err.Error())
		}

		c.Cookie(&fiber.Cookie{
			Name:    "token",
			Expires: time.Now().Add(-(time.Hour * 2)),
			//HTTPOnly: true,
			SameSite: "lax",
		})

		return c.SendStatus(fiber.StatusNoContent)
	}
}
