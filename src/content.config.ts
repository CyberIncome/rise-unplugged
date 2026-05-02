import { defineCollection, z } from 'astro:content';

const guides = defineCollection({
  type: 'content',
  schema: z.object({
    title: z.string(),
    description: z.string(),
    status: z.enum(['draft', 'review', 'published']).default('draft'),
    pillar: z.string(),
    riskLevel: z.enum(['low', 'medium', 'high']),
    expertReview: z.enum(['not-needed', 'preferred', 'required']),
    created: z.string(),
    lastReviewed: z.string().optional(),
    featured: z.boolean().default(false),
  }),
});

export const collections = { guides };
